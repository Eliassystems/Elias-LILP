param(
    [Parameter(Mandatory=$true)]
    [string]$BindingRecordPath,

    [Parameter(Mandatory=$true)]
    [string]$BindingProvenancePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ExpectedIdentifier = "ELIAS-LILP-LEX-001"
$ExpectedVersion    = "v0.1"
$ExpectedSHA256     = "144EFB9CAAB7A0F0537A84704626AC58C5659A0B50F92AA64086B07918E63488"

foreach ($Path in @(
    $BindingRecordPath,
    $BindingProvenancePath
)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required governed evidence does not exist: $Path"
    }
}

$BindingRaw =
    Get-Content -LiteralPath $BindingRecordPath -Raw

$ProvenanceRaw =
    Get-Content -LiteralPath $BindingProvenancePath -Raw

$IdentifierMatches =
    [regex]::Matches(
        $BindingRaw,
        '(?im)^\s*(?:LexiconIdentifier|LexiconId|Lexicon ID|Identifier)\s*[:=]\s*["'']?([A-Za-z0-9._-]+)'
    )

$VersionMatches =
    [regex]::Matches(
        $BindingRaw,
        '(?im)^\s*(?:LexiconVersion|Lexicon Version|Version)\s*[:=]\s*["'']?(v[0-9]+(?:\.[0-9]+)+)'
    )

$HashMatches =
    [regex]::Matches(
        $BindingRaw,
        '(?im)^\s*(?:LexiconSHA256|Lexicon SHA-256|SHA-256|SHA256)\s*[:=]\s*["'']?([A-Fa-f0-9]{64})'
    )

$ObservedIdentifier =
    if ($IdentifierMatches.Count -eq 1) {
        $IdentifierMatches[0].Groups[1].Value
    }
    else {
        $null
    }

$ObservedVersion =
    if ($VersionMatches.Count -eq 1) {
        $VersionMatches[0].Groups[1].Value
    }
    else {
        $null
    }

$ObservedSHA256 =
    if ($HashMatches.Count -eq 1) {
        $HashMatches[0].Groups[1].Value.ToUpperInvariant()
    }
    else {
        $null
    }

$ExtractionComplete =
    $IdentifierMatches.Count -eq 1 -and
    $VersionMatches.Count -eq 1 -and
    $HashMatches.Count -eq 1

$IdentifierEqual =
    $ExtractionComplete -and
    $ObservedIdentifier -ceq $ExpectedIdentifier

$VersionEqual =
    $ExtractionComplete -and
    $ObservedVersion -ceq $ExpectedVersion

$SHA256Equal =
    $ExtractionComplete -and
    $ObservedSHA256 -ceq $ExpectedSHA256

$MechanicalEquality =
    $IdentifierEqual -and
    $VersionEqual -and
    $SHA256Equal

$Determination =
    if (-not $ExtractionComplete) {
        "NOT_ESTABLISHED"
    }
    elseif ($MechanicalEquality) {
        "MECHANICAL_IDENTITY_MATCH"
    }
    else {
        "FAIL"
    }

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-007-v0.2"
    SupersedesImplementationId = "LILP-HI-FREEZE-007-v0.1"
    HarnessDefinitionId = "LILP-HB-FREEZE-007-v0.1"

    BindingRecordPath =
        (Resolve-Path -LiteralPath $BindingRecordPath).Path

    BindingRecordSHA256 =
        (Get-FileHash -LiteralPath $BindingRecordPath -Algorithm SHA256).Hash

    BindingProvenancePath =
        (Resolve-Path -LiteralPath $BindingProvenancePath).Path

    BindingProvenanceSHA256 =
        (Get-FileHash -LiteralPath $BindingProvenancePath -Algorithm SHA256).Hash

    ProvenanceContentCaptured =
        -not [string]::IsNullOrWhiteSpace($ProvenanceRaw)

    IdentifierMatchCount = $IdentifierMatches.Count
    VersionMatchCount    = $VersionMatches.Count
    SHA256MatchCount     = $HashMatches.Count

    ExpectedIdentifier = $ExpectedIdentifier
    ObservedIdentifier = $ObservedIdentifier
    IdentifierEqual    = $IdentifierEqual

    ExpectedVersion = $ExpectedVersion
    ObservedVersion = $ObservedVersion
    VersionEqual    = $VersionEqual

    ExpectedSHA256 = $ExpectedSHA256
    ObservedSHA256 = $ObservedSHA256
    SHA256Equal    = $SHA256Equal

    MechanicalEquality = $MechanicalEquality
    Determination      = $Determination

    AuthorityBoundary =
        "EXACT_EXTRACTION_AND_EQUALITY_ONLY_PROVENANCE_AND_LINEAGE_MUST_BE_GOVERNED_EVIDENCE"
}