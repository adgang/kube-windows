# Copyright 2018-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

[CmdLetBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName = 'vpc-admission-webhook-svc',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SecretName = 'vpc-admission-webhook-certs',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace = 'kube-system'
)
$ErrorActionPreference = 'Stop'

if (!(Get-Command -Name 'openssl' -ErrorAction:SilentlyContinue)) {
    throw 'openssl not found'
}
if (!(Get-Command -Name 'kubectl' -ErrorAction:SilentlyContinue)) {
    throw 'kubectl not found'
}
Switch ((Get-Command -Name 'Out-File').Parameters['Encoding'].ParameterType.Name) {
    'String' {
        # PowerShell w/ Full .Net
        [string]$OutFileEncoding = 'ASCII'
    }
    Default { # Assumes 'Encoding'
        # PowerShell.Core w/ Full .netcore
        [System.Text.Encoding]$OutFileEncoding = [System.Text.Encoding]::GetEncoding('ASCII')
    }
}

$TempDirectoryPath = [System.IO.Path]::Combine($ENV:Temp, ([System.IO.Path]::GetRandomFileName()))
$TempDirectory = New-Item -Type:Directory -Path $TempDirectoryPath
Write-Verbose "Creating certificates in path: $TempDirectoryPath"

$csrFilePath = [System.IO.Path]::Combine($TempDirectory, 'server.csr')
$csrConfFilePath = [System.IO.Path]::Combine($TempDirectory, 'csr.conf')
$csrConfFilePath = [System.IO.Path]::Combine($TempDirectory, 'csr.conf')
$csrK8sConfFilePath = [System.IO.Path]::Combine($TempDirectory, 'csr.yaml')
$serverCertificateKeyFilePath = [System.IO.Path]::Combine($TempDirectory, 'server-key.pem')
$serverCertificateFilePath = [System.IO.Path]::Combine($TempDirectory, 'server-cert.pem')

$csrName = ('{0}.{1}' -f $ServiceName, $Namespace)
$serviceAddress = ('{0}.svc' -f $csrName)
$csrConf = @"
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $ServiceName
DNS.2 = $csrName
DNS.3 = $serviceAddress
"@

Out-File -InputObject $csrConf -FilePath $csrConfFilePath -Encoding $OutFileEncoding

$cmd = "openssl genrsa -out `"$serverCertificateKeyFilePath`" 2048"
Write-Verbose $cmd
Invoke-Expression -Command $cmd

$cmd = "openssl req -new -key `"$serverCertificateKeyFilePath`" -subj `"/CN=$serviceAddress`" -out `"$csrFilePath`" -config `"$csrConfFilePath`""
Write-Verbose $cmd
Invoke-Expression -Command $cmd

Write-Verbose ('Converting openssl csr to base64 encoded bytes...')
$csrRequestData = Invoke-Expression -Command "[Convert]::ToBase64String([System.IO.File]::ReadAllBytes(`"$csrFilePath`"))"

Write-Verbose 'Cleaning up any previously created CSR'
try {
    Invoke-Expression -Command "kubectl delete csr $csrName" 2>&1
} catch {
    Write-Verbose $_
}

Write-Verbose 'Creating server CSR'
$csrK8sConf = @"
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $csrName
spec:
  groups:
  - system:authenticated
  request: $csrRequestData
  usages:
  - digital signature
  - key encipherment
  - server auth
"@

Out-File -InputObject $csrK8sConf -FilePath $csrK8sConfFilePath -Encoding $OutFileEncoding
Invoke-Expression -Command "kubectl create -f `"$csrK8sConfFilePath`""

Write-Verbose 'Verifying CSR has been created'
[int]$tries = 10
[int]$delay = 1
[bool]$Succeeded = $false
do {
    try {
        Invoke-Expression -Command "kubectl get csr $csrName"
        $Succeeded = $true
    } catch {
        $Succeeded = $false
    }
    if (-not $Succeeded) {
        $tries--
        Start-Sleep -Seconds $delay
    }
} while (-not $Succeeded -and $tries -ge 0)
if (-not $Succeeded) {
    throw "Failed to verify Certificate Signing Request (CSR)"
}

Write-Verbose 'Approving server CSR'
Invoke-Expression -Command "kubectl certificate approve $csrName"

Write-Verbose 'Getting signed certificate'
[int]$tries = 10
[int]$delay = 1
[bool]$Succeeded = $false
do {
    try {
        $serverCertificate = Invoke-Expression -Command "kubectl get csr $csrName -o jsonpath='{.status.certificate}'"
        $Succeeded = $true
    } catch {
        $Succeeded = $false
    }
    if (-not $Succeeded) {
        $tries--
        Start-Sleep -Seconds $delay
    }
} while (-not $Succeeded -and $tries -ge 0)
if (-not $Succeeded -or $null -eq $serverCertificate) {
    throw 'Failed to get approved csr data'
}

Write-Verbose 'Writing signed certificate'
Invoke-Expression -Command "Write-Output `"$serverCertificate`" | openssl base64 -d -A -out `"$serverCertificateFilePath`""

Write-Verbose 'Creating secret with CA certificate and server certificate'
$cmd = "kubectl create secret generic $SecretName " + `
            "--from-file=key.pem=`"$serverCertificateKeyFilePath`" " + `
            "--from-file=cert.pem=`"$serverCertificateFilePath`" " + `
            "--dry-run -o yaml | " + `
                "kubectl -n $Namespace apply -f -"
Write-Verbose $cmd
Invoke-Expression -Command $cmd
