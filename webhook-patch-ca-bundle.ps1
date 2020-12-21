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
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DeploymentTemplateFilePath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFilePath
)

if (!(Get-Command -Name 'kubectl' -ErrorAction:SilentlyContinue)) {
    throw 'kubectl not found'
}

Write-Verbose 'Getting CA bundle'
$cmd = 'kubectl config view --raw -o json --minify'
Write-Verbose $cmd
[string]$ret = Invoke-Expression -Command $cmd
$kubeConfig = ConvertFrom-Json -InputObject $ret
$clusterConfig = $kubeConfig.clusters[0].cluster
$CaBundle = $clusterConfig."certificate-authority-data"

Write-Verbose 'Constructing new deployment YAML content'
$newTemplate = Get-Content -Path $DeploymentTemplateFilePath | ForEach-Object {
    $_ -replace '\${CA_BUNDLE}', $CaBundle
}
Write-Verbose ('Updating deployment YAML: {0}' -f $OutputFilePath)
Write-Verbose ($newTemplate | Out-String)
Out-File -FilePath $OutputFilePath -InputObject $newTemplate
