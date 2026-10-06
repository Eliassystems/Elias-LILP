param(
    [Parameter(Mandatory=$true)]
    [string]$CandidatePath,

    [Parameter(Mandatory=$true)]
    [string]$LexiconPath,

    [Parameter(Mandatory=$true)]
    [string]$MaterialTermInventoryPath,

    [Parameter(Mandatory=$true)]
    [string]$HumanReviewRecordPath,

    [Parameter(Mandatory=$true)]
    [string]$ReviewerId,

    [Parameter(Mandatory=$true)]
    [string]$ReviewerAuthority
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

foreach ($Path in @(
    $CandidatePath,
    $LexiconPath,
    $MaterialTermInventoryPath,
    $HumanReviewRecordPath
)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required review input does not exist: $Path"
    }
}

$CandidateContent =
    Get-Content -LiteralPath $CandidatePath -Raw

$LexiconContent =
    Get-Content -LiteralPath $LexiconPath -Raw

$Inventory =
    @(Import-Csv -LiteralPath $MaterialTermInventoryPath)

$HumanReview =
    @(Import-Csv -LiteralPath $HumanReviewRecordPath)

$RequiredInventoryColumns =
    @("Term")

$RequiredReviewColumns =
    @("Term","HumanClassification","Evidence","ReviewerRationale")

foreach ($Column in $RequiredInventoryColumns) {
    if ($Inventory.Count -eq 0 -or
        -not ($Inventory[0].PSObject.Properties.Name -contains $Column)) {
        throw "Material-term inventory missing required column: $Column"
    }
}

foreach ($Column in $RequiredReviewColumns) {
    if ($HumanReview.Count -eq 0 -or
        -not ($HumanReview[0].PSObject.Properties.Name -contains $Column)) {
        throw "Human review record missing required column: $Column"
    }
}

$AllowedClassifications =
    @(
        "COMPATIBLE",
        "EXPLICITLY_NARROWED",
        "MATERIAL_CONFLICT"
    )

$TermResults =
    [System.Collections.Generic.List[object]]::new()

$Incomplete = $false

foreach ($InventoryRow in $Inventory) {

    $Term =
        [string]$InventoryRow.Term

    $ReviewRows = @(
        $HumanReview |
            Where-Object {
                $_.Term -ceq $Term
            }
    )

    if ($ReviewRows.Count -ne 1) {

        $Incomplete = $true

        $TermResults.Add(
            [pscustomobject][ordered]@{
                Term = $Term
                HumanClassification = "NOT_ESTABLISHED"
                Evidence = $null
                ReviewerRationale = $null
                ReviewRecordCount = $ReviewRows.Count
            }
        )

        continue
    }

    $R = $ReviewRows[0]

    $Classification =
        ([string]$R.HumanClassification).ToUpperInvariant()

    if ($Classification -notin $AllowedClassifications) {
        $Incomplete = $true
    }

    if ([string]::IsNullOrWhiteSpace([string]$R.Evidence) -or
        [string]::IsNullOrWhiteSpace([string]$R.ReviewerRationale)) {
        $Incomplete = $true
    }

    $TermResults.Add(
        [pscustomobject][ordered]@{
            Term = $Term
            HumanClassification = $Classification
            Evidence = $R.Evidence
            ReviewerRationale = $R.ReviewerRationale
            ReviewRecordCount = 1
        }
    )
}

$MaterialConflicts = @(
    $TermResults |
        Where-Object {
            $_.HumanClassification -eq "MATERIAL_CONFLICT"
        }
)

$MechanicalAggregation =
    if ($Incomplete) {
        "NOT_ESTABLISHED"
    }
    elseif ($MaterialConflicts.Count -gt 0) {
        "HUMAN_REVIEW_RECORDED_MATERIAL_CONFLICT"
    }
    else {
        "HUMAN_REVIEW_COMPLETE_NO_RECORDED_MATERIAL_CONFLICT"
    }

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-010-v0.2"
    SupersedesImplementationId = "LILP-HI-FREEZE-010-v0.1"
    HarnessDefinitionId = "LILP-HB-FREEZE-010-v0.1"

    CandidatePath =
        (Resolve-Path -LiteralPath $CandidatePath).Path

    CandidateSHA256 =
        (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash

    CandidateContentPresented =
        -not [string]::IsNullOrWhiteSpace($CandidateContent)

    LexiconPath =
        (Resolve-Path -LiteralPath $LexiconPath).Path

    LexiconSHA256 =
        (Get-FileHash -LiteralPath $LexiconPath -Algorithm SHA256).Hash

    LexiconContentPresented =
        -not [string]::IsNullOrWhiteSpace($LexiconContent)

    MaterialTermInventoryPath =
        (Resolve-Path -LiteralPath $MaterialTermInventoryPath).Path

    MaterialTermInventorySHA256 =
        (Get-FileHash -LiteralPath $MaterialTermInventoryPath -Algorithm SHA256).Hash

    HumanReviewRecordPath =
        (Resolve-Path -LiteralPath $HumanReviewRecordPath).Path

    HumanReviewRecordSHA256 =
        (Get-FileHash -LiteralPath $HumanReviewRecordPath -Algorithm SHA256).Hash

    ReviewerId =
        $ReviewerId

    ReviewerAuthority =
        $ReviewerAuthority

    TermCount =
        $Inventory.Count

    HumanClassification =
        @($TermResults)

    TermDetermination =
        $MechanicalAggregation

    MaterialConflictCount =
        $MaterialConflicts.Count

    AutomationAuthority =
        "VALIDATION_AGGREGATION_AND_EVIDENCE_RECORDING_ONLY"

    HumanAuthority =
        "TERM_MEANING_SEMANTIC_COMPATIBILITY_MATERIALITY_AND_NORMATIVE_CONFLICT"
}