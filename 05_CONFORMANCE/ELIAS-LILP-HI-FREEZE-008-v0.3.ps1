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

$GlobalHashMatches =
    @(
        [regex]::Matches(
            $BindingRaw,
            [regex]::Escape($ExpectedSHA256),
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    )

$RequirementPattern =
    '(?ms)' +
    [regex]::Escape("LILP-REQ-FREEZE-008") +
    '\s+' +
    'The\s+founding\s+provenance\s+binding\s+SHALL\s+continue\s+to\s+identify\s+SHA-256:\s*' +
    '([A-Fa-f0-9]{64})'

$RequirementMatches =
    @(
        [regex]::Matches(
            $BindingRaw,
            $RequirementPattern
        )
    )

$ObservedSHA256 =
    if ($RequirementMatches.Count -eq 1) {

        $RequirementMatches[0].Groups[1].Value.ToUpperInvariant()
    }
    else {

        ""
    }

$SHA256Equal =
    (
        $RequirementMatches.Count -eq 1 -and
        $ObservedSHA256 -ceq $ExpectedSHA256
    )

$LineageEvidencePresent =
    -not [string]::IsNullOrWhiteSpace($LineageRaw)

$Receipt0001Reference =
    (
        $LineageRaw -match 'RECEIPT-0001' -or
        $LineageRaw -match 'Receipt 0001'
    )

$FoundingProvenanceReference =
    (
        $LineageRaw -match 'FOUNDING.PROVENANCE' -or
        $LineageRaw -match 'founding provenance'
    )

$OverwriteReference =
    (
        $LineageRaw -match 'overwrite' -or
        $LineageRaw -match 'overwritten'
    )

$UnavailableHistoricalState =
    (
        $LineageRaw -match 'not established' -or
        $LineageRaw -match 'not available' -or
        $LineageRaw -match 'missing' -or
        $LineageRaw -match 'unavailable'
    )

$NonRetrospectiveRepairBoundary =
    (
        $LineageRaw -match 'retrospective repair' -or
        $LineageRaw -match 'not.*recreated.*original' -or
        $LineageRaw -match 'not.*represented.*original' -or
        $LineageRaw -match 'no.*repair'
    )

$LineageConditionsPresent =
    (
        $LineageEvidencePresent -and
        $Receipt0001Reference -and
        $FoundingProvenanceReference -and
        $OverwriteReference -and
        $UnavailableHistoricalState -and
        $NonRetrospectiveRepairBoundary
    )

$ExtractionComplete =
    (
        $RequirementMatches.Count -eq 1 -and
        -not [string]::IsNullOrWhiteSpace($ObservedSHA256)
    )

$MechanicalPass =
    (
        $ExtractionComplete -and
        $SHA256Equal -and
        $LineageConditionsPresent
    )

$Determination =
    if (-not $ExtractionComplete) {

        "NOT_ESTABLISHED"
    }
    elseif ($MechanicalPass) {

        "PASS"
    }
    else {

        "FAIL"
    }

[pscustomobject][ordered]@{

    HarnessImplementationId =
        "LILP-HI-FREEZE-008-v0.3"

    SupersedesImplementationId =
        "LILP-HI-FREEZE-008-v0.2"

    HarnessDefinitionId =
        "LILP-HB-FREEZE-008-v0.1"

    RequirementId =
        "LILP-REQ-FREEZE-008"

    TestCaseId =
        "LILP-TC-T14-015"

    VerificationMethodId =
        "LILP-VM-FREEZE-008-v0.1"

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

    GlobalSHA256MatchCount =
        $GlobalHashMatches.Count

    RequirementContextMatchCount =
        $RequirementMatches.Count

    ExpectedSHA256 =
        $ExpectedSHA256

    ObservedSHA256 =
        $ObservedSHA256

    SHA256Equal =
        $SHA256Equal

    Receipt0001Reference =
        $Receipt0001Reference

    FoundingProvenanceReference =
        $FoundingProvenanceReference

    OverwriteReference =
        $OverwriteReference

    UnavailableHistoricalState =
        $UnavailableHistoricalState

    NonRetrospectiveRepairBoundary =
        $NonRetrospectiveRepairBoundary

    LineageConditionsPresent =
        $LineageConditionsPresent

    ExtractionComplete =
        $ExtractionComplete

    MechanicalPass =
        $MechanicalPass

    Determination =
        $Determination

    AuthorityType =
        "DETERMINISTIC_MECHANICAL"

    AuthorityBoundary =
        "FREEZE008_CONTEXTUAL_EXTRACTION_AND_LINEAGE_PRESENCE_ONLY"

    ExecutionAuthority =
        "NONE"

    ConsequenceExecuted =
        $false

    ResultScope =
        "LILP-TC-T14-015_MECHANICAL_ONLY"
}
