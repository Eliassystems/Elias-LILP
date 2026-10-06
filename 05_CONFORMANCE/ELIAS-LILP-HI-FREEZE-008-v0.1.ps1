param(
    [Parameter(Mandatory=$true)]
    [string]$BindingRecordPath,

    [Parameter(Mandatory=$true)]
    [string]$ObservedSHA256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ExpectedSHA256 =
    "2754F23DB9E41A2423D4F7749C617A488D76CE4D9C879A5AA70EFB7755D40E43"

if (-not (Test-Path -LiteralPath $BindingRecordPath -PathType Leaf)) {
    throw "Founding provenance binding record does not exist."
}

$BindingRecordHash =
    (Get-FileHash -LiteralPath $BindingRecordPath -Algorithm SHA256).Hash

$HashEqual =
    $ObservedSHA256.ToUpperInvariant() -ceq $ExpectedSHA256

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-008-v0.1"
    HarnessDefinitionId     = "LILP-HB-FREEZE-008-v0.1"
    BindingRecordPath       = (Resolve-Path -LiteralPath $BindingRecordPath).Path
    BindingRecordSHA256     = $BindingRecordHash
    ExpectedSHA256          = $ExpectedSHA256
    ObservedSHA256          = $ObservedSHA256.ToUpperInvariant()
    SHA256Equal             = $HashEqual
    MechanicalResult        = $HashEqual
    AttributionStatus       = "REQUIRES_GOVERNED_LINEAGE_EVIDENCE"
    ExecutionAuthority      = "EXACT_VALUE_COMPARISON_ONLY"
}