# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

<#
.DESCRIPTION
Creates a vpc-admission-webhook deployment config yaml for an EKS kubernetes cluster

.SYNOPSIS
Creates a vpc-admission-webhook deployment config yaml for an EKS kubernetes cluster

.PARAMETER DeploymentTemplate
(Required) The path to the template yaml file for the vpc-admission-webhook

.PARAMETER Outfile
The file to write the deployment configuration out to

.PARAMETER ServiceName
The name of the vpc-admission-webhook

.PARAMETER SecretName
The name of the secret deployed for use with the vpc-admission-webhook

.PARAMETER Namespace
The kubernetes namespace to target

.PARAMETER DryRun
A switch that, when enabled, will generate the artifacts and pre-requisites for
deploying the vpc-admission-webhook, but will return the config yaml content
rather than applying it to the cluster

#>
Param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$DeploymentTemplate,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Outfile = 'vpc-admission-webhook.yaml',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName = 'vpc-admission-webhook-svc',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SecretName = 'vpc-admission-webhook-certs',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace = 'kube-system',

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$createCertScript   = [System.IO.Path]::Combine($PSScriptRoot, 'webhook-create-signed-cert.ps1')
$caBundleScript     = [System.IO.Path]::Combine($PSScriptRoot, 'webhook-patch-ca-bundle.ps1')
if (-not (Test-Path -Path $createCertScript)) {
    throw "File missing: $createCertScript"
}
if (-not (Test-Path -Path $caBundleScript)) {
    throw "File missing: $caBundleScript"
}

# Setup secret for secure communication
Invoke-Expression -Command "& '$createCertScript' -ServiceName $ServiceName -SecretName $SecretName -Namespace $Namespace"

# Verify secret
Invoke-Expression -Command "kubectl get secret -n $Namespace $SecretName" 2>&1

# Configure webhook and create deployment file
Invoke-Expression -Command "& '$caBundleScript' -DeploymentTemplateFilePath `"$DeploymentTemplate`" -OutputFilePath `"$Outfile`""

if ($DryRun) {
    Write-Output (Get-Content -Path $Outfile)
} else {
    Invoke-Expression -Command "kubectl -n $Namespace apply -f `"$Outfile`"" 2>&1
}