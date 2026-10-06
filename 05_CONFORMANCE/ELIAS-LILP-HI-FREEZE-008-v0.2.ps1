param(
    [Parameter(Mandatory=$true)]
    [string]$BindingRecordPath,

    [Parameter(Mandatory=$true)]
    [string]$LineageEvidencePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ExpectedSHA256 =
    "2754F23DB9E41A2423D4F7749C617A488D76CE4D9C879A5AA70EFB7755D40E43"

foreach ($Path in @(
    $BindingRecordPath,
    $LineageEvidencePath
)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required governed evidence does not exist: $Path"
    }
}

$BindingRaw =
    Get-Content -LiteralPath $BindingRecordPath -Raw

$LineageRaw =
    Get-Content -LiteralPath $LineageEvidencePath -Raw

$HashMatches =
    [regex]::Matches(
        $BindingRaw,
        '(?im)^\s*(?:FoundingProvenanceSHA256|Founding Provenance SHA-256|FoundingSHA256|SHA-256|SHA256)\s*[:=]\s*["'']?([A-Fa-f0-9]{64})'
    )

$ObservedSHA256 =
    if ($HashMatches.Count -eq 1) {
        $HashMatches[0].Groups[1].Value.ToUpperInvariant()
    }
    else {
        $null
    }

$ExtractionComplete =
    $HashMatches.Count -eq 1

$SHA256Equal =
    $ExtractionComplete -and
    $ObservedSHA256 -ceq $ExpectedSHA256

$LineageEvidencePresent =
    -not [string]::IsNullOrWhiteSpace($LineageRaw)

$Determination =
    if (-not $ExtractionComplete -or -not $LineageEvidencePresent) {
        "NOT_ESTABLISHED"
    }
    elseif ($SHA256Equal) {
        "MECHANICAL_IDENTITY_MATCH"
    }
    else {
        "FAIL"
    }

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-008-v0.2"
    SupersedesImplementationId = "LILP-HI-FREEZE-008-v0.1"
    HarnessDefinitionId = "LILP-HB-FREEZE-008-v0.1"

    BindingRecordPath =
        (Resolve-Path -LiteralPath $BindingRecordPath).Path

    BindingRecordSHA256 =
        (Get-FileHash -LiteralPath $BindingRecordPath -Algorithm SHA256).Hash

    LineageEvidencePath =
        (Resolve-Path -LiteralPath $LineageEvidencePath).Path

    LineageEvidenceSHA256 =
        (Get-FileHash -LiteralPath $LineageEvidencePath -Algorithm SHA256).Hash

    LineageEvidencePresent =
        $LineageEvidencePresent

    SHA256MatchCount =
        $HashMatches.Count

    ExpectedSHA256 =
        $ExpectedSHA256

    ObservedSHA256 =
        $ObservedSHA256

    SHA256Equal =
        $SHA256Equal

    Determination =
        $Determination

    AuthorityBoundary =
        "EXACT_EXTRACTION_AND_EQUALITY_ONLY_ATTRIBUTION_AND_LINEAGE_REMAIN_GOVERNED_EVIDENCE"
}