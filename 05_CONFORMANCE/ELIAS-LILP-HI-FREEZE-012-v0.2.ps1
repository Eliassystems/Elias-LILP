param(
    [Parameter(Mandatory=$true)]
    [string]$ClaimArtifactPath,

    [Parameter(Mandatory=$true)]
    [string]$InternalStatus,

    [Parameter(Mandatory=$true)]
    [string]$ApplicableProfile,

    [Parameter(Mandatory=$true)]
    [string]$HumanReviewRecordPath,

    [Parameter(Mandatory=$true)]
    [string]$ReviewerId,

    [Parameter(Mandatory=$true)]
    [string]$ReviewerAuthority,

    [string]$ExternalAuthorityEvidencePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

foreach ($Path in @(
    $ClaimArtifactPath,
    $HumanReviewRecordPath
)) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required review input does not exist: $Path"
    }
}

$ClaimContent =
    Get-Content -LiteralPath $ClaimArtifactPath -Raw

$HumanReview =
    @(Import-Csv -LiteralPath $HumanReviewRecordPath)

$RequiredColumns =
    @(
        "Category",
        "HumanDetermination",
        "Evidence",
        "ReviewerRationale"
    )

foreach ($Column in $RequiredColumns) {
    if ($HumanReview.Count -eq 0 -or
        -not ($HumanReview[0].PSObject.Properties.Name -contains $Column)) {
        throw "Human claim-review record missing required column: $Column"
    }
}

$RequiredCategories =
    @(
        "ISO_ADOPTION",
        "IEC_ADOPTION",
        "REGULATORY_APPROVAL",
        "GOVERNMENT_APPROVAL",
        "INDEPENDENT_CERTIFICATION",
        "INDUSTRY_WIDE_ADOPTION"
    )

$AllowedDeterminations =
    @(
        "NO_EXTERNAL_STATUS_IMPLIED",
        "EXTERNAL_STATUS_ASSERTED_SUPPORTED",
        "EXTERNAL_STATUS_ASSERTED_UNSUPPORTED",
        "AMBIGUOUS"
    )

$CategoryResults =
    [System.Collections.Generic.List[object]]::new()

$Incomplete = $false

foreach ($Category in $RequiredCategories) {

    $Rows = @(
        $HumanReview |
            Where-Object {
                $_.Category -ceq $Category
            }
    )

    if ($Rows.Count -ne 1) {

        $Incomplete = $true

        $CategoryResults.Add(
            [pscustomobject][ordered]@{
                Category = $Category
                HumanDetermination = "NOT_ESTABLISHED"
                Evidence = $null
                ReviewerRationale = $null
                ReviewRecordCount = $Rows.Count
            }
        )

        continue
    }

    $R = $Rows[0]

    $HumanDetermination =
        ([string]$R.HumanDetermination).ToUpperInvariant()

    if ($HumanDetermination -notin $AllowedDeterminations) {
        $Incomplete = $true
    }

    if ([string]::IsNullOrWhiteSpace([string]$R.Evidence) -or
        [string]::IsNullOrWhiteSpace([string]$R.ReviewerRationale)) {
        $Incomplete = $true
    }

    $CategoryResults.Add(
        [pscustomobject][ordered]@{
            Category = $Category
            HumanDetermination = $HumanDetermination
            Evidence = $R.Evidence
            ReviewerRationale = $R.ReviewerRationale
            ReviewRecordCount = 1
        }
    )
}

$ExternalEvidence = $null

if (-not [string]::IsNullOrWhiteSpace($ExternalAuthorityEvidencePath)) {

    if (-not (Test-Path -LiteralPath $ExternalAuthorityEvidencePath -PathType Leaf)) {
        throw "External authority evidence does not exist."
    }

    $ExternalEvidence =
        [pscustomobject][ordered]@{
            Path =
                (Resolve-Path -LiteralPath $ExternalAuthorityEvidencePath).Path

            SHA256 =
                (Get-FileHash -LiteralPath $ExternalAuthorityEvidencePath -Algorithm SHA256).Hash

            Content =
                (Get-Content -LiteralPath $ExternalAuthorityEvidencePath -Raw)
        }
}

$UnsafeFindings = @(
    $CategoryResults |
        Where-Object {
            $_.HumanDetermination -in @(
                "EXTERNAL_STATUS_ASSERTED_UNSUPPORTED",
                "AMBIGUOUS"
            )
        }
)

$HumanClaimDetermination =
    if ($Incomplete) {
        "NOT_ESTABLISHED"
    }
    elseif ($UnsafeFindings.Count -gt 0) {
        "HUMAN_REVIEW_RECORDED_CLAIM_CEILING_ISSUE"
    }
    else {
        "HUMAN_REVIEW_COMPLETE"
    }

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-012-v0.2"
    SupersedesImplementationId = "LILP-HI-FREEZE-012-v0.1"
    HarnessDefinitionId = "LILP-HB-FREEZE-012-v0.1"

    ClaimArtifactPath =
        (Resolve-Path -LiteralPath $ClaimArtifactPath).Path

    ClaimArtifactSHA256 =
        (Get-FileHash -LiteralPath $ClaimArtifactPath -Algorithm SHA256).Hash

    ClaimContent =
        $ClaimContent

    InternalStatus =
        $InternalStatus

    ApplicableProfile =
        $ApplicableProfile

    HumanReviewRecordPath =
        (Resolve-Path -LiteralPath $HumanReviewRecordPath).Path

    HumanReviewRecordSHA256 =
        (Get-FileHash -LiteralPath $HumanReviewRecordPath -Algorithm SHA256).Hash

    ReviewerId =
        $ReviewerId

    ReviewerAuthority =
        $ReviewerAuthority

    SixCategoryReview =
        @($CategoryResults)

    ExternalAuthorityEvidence =
        $ExternalEvidence

    HumanDetermination =
        $HumanClaimDetermination

    AutomationAuthority =
        "STRUCTURE_VALIDATION_AGGREGATION_AND_EVIDENCE_RECORDING_ONLY"

    HumanAuthority =
        "MATERIALLY_CONVEYED_MEANING_AMBIGUITY_AND_EXTERNAL_AUTHORITY_SUFFICIENCY"
}