param(
    [Parameter(Mandatory=$true)]
    [string]$BindingRecordPath,

    [Parameter(Mandatory=$true)]
    [string]$ObservedIdentifier,

    [Parameter(Mandatory=$true)]
    [string]$ObservedVersion,

    [Parameter(Mandatory=$true)]
    [string]$ObservedSHA256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ExpectedIdentifier =
    "ELIAS-LILP-LEX-001"

$ExpectedVersion =
    "v0.1"

$ExpectedSHA256 =
    "144EFB9CAAB7A0F0537A84704626AC58C5659A0B50F92AA64086B07918E63488"

if (-not (Test-Path -LiteralPath $BindingRecordPath -PathType Leaf)) {
    throw "Binding record does not exist."
}

$BindingRecordHash =
    (Get-FileHash -LiteralPath $BindingRecordPath -Algorithm SHA256).Hash

$IdentifierEqual =
    $ObservedIdentifier -ceq $ExpectedIdentifier

$VersionEqual =
    $ObservedVersion -ceq $ExpectedVersion

$HashEqual =
    $ObservedSHA256.ToUpperInvariant() -ceq $ExpectedSHA256

$MechanicalResult =
    $IdentifierEqual -and
    $VersionEqual -and
    $HashEqual

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-007-v0.1"
    HarnessDefinitionId     = "LILP-HB-FREEZE-007-v0.1"
    BindingRecordPath       = (Resolve-Path -LiteralPath $BindingRecordPath).Path
    BindingRecordSHA256     = $BindingRecordHash
    ExpectedIdentifier      = $ExpectedIdentifier
    ObservedIdentifier      = $ObservedIdentifier
    IdentifierEqual         = $IdentifierEqual
    ExpectedVersion         = $ExpectedVersion
    ObservedVersion         = $ObservedVersion
    VersionEqual            = $VersionEqual
    ExpectedSHA256          = $ExpectedSHA256
    ObservedSHA256          = $ObservedSHA256.ToUpperInvariant()
    SHA256Equal             = $HashEqual
    MechanicalResult        = $MechanicalResult
    AttributionStatus       = "REQUIRES_GOVERNED_BINDING_PROVENANCE"
    ExecutionAuthority      = "EXACT_VALUE_COMPARISON_ONLY"
}