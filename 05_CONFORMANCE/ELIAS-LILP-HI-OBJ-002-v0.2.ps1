param(
    [Parameter(Mandatory = $true)]
    [string]$CandidatePath,

    [Parameter(Mandatory = $true)]
    [string[]]$ComparisonVersion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ImplementationId = "LILP-HI-OBJ-002-v0.2"
$SupersedesImplementationId = "LILP-HI-OBJ-002-v0.1"
$HarnessDefinitionId = "LILP-HB-OBJ-002-v0.1"
$RequirementId = "LILP-REQ-OBJ-002"
$TestCaseId = "LILP-TC-T02-009"
$VerificationMethodId = "LILP-VM-OBJ-002-v0.1"
$HarnessMode = "DETERMINISTIC_CSV_OBJECTVERSION_IDENTITY_INSPECTION"
$AuthorityType = "DETERMINISTIC_MECHANICAL"
$AuthorityBoundary = "EXPLICIT_CSV_OBJECTVERSION_FIELD_EXTRACTION_AND_EXACT_COMPARISON_ONLY_NO_FILENAME_INFERENCE_NO_SEMANTIC_OR_GOVERNANCE_INFERENCE"

if (-not (Test-Path -LiteralPath $CandidatePath -PathType Leaf)) {
    throw "CandidatePath does not identify an existing file."
}

if ($ComparisonVersion.Count -eq 0) {
    throw "At least one governed comparison version is required."
}

$ComparisonValues = @(
    $ComparisonVersion |
    ForEach-Object {
        [string]$_
    }
)

$ComparisonValuesValid = (
    @(
        $ComparisonValues |
        Where-Object {
            [string]::IsNullOrWhiteSpace($_)
        }
    ).Count -eq 0
)

$CandidateSHA256 =
    (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash

$CandidateBytes =
    (Get-Item -LiteralPath $CandidatePath).Length

$Rows =
    @(Import-Csv -LiteralPath $CandidatePath)

$RowCount =
    $Rows.Count

$Columns =
    @()

if ($RowCount -gt 0) {
    $Columns =
        @($Rows[0].PSObject.Properties.Name)
}

$ObjectVersionColumnCount =
    @(
        $Columns |
        Where-Object {
            $_ -ceq "ObjectVersion"
        }
    ).Count

$ExplicitPresent =
    ($ObjectVersionColumnCount -eq 1)

$VersionValues =
    @()

if ($ExplicitPresent -and $RowCount -gt 0) {

    $VersionValues =
        @(
            $Rows |
            ForEach-Object {
                [string]$_.ObjectVersion
            }
        )
}

$NonEmptyVersionValues =
    @(
        $VersionValues |
        Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        }
    )

$NonEmpty =
    (
        $ExplicitPresent -and
        $RowCount -gt 0 -and
        $VersionValues.Count -eq $RowCount -and
        $NonEmptyVersionValues.Count -eq $RowCount
    )

$UniqueVersionValues =
    @(
        $NonEmptyVersionValues |
        Sort-Object -Unique
    )

$Unambiguous =
    (
        $NonEmpty -and
        $UniqueVersionValues.Count -eq 1
    )

$ObservedVersion =
    ""

if ($Unambiguous) {
    $ObservedVersion =
        [string]$UniqueVersionValues[0]
}

$VersionMatchCount =
    if ($Unambiguous) {
        $RowCount
    }
    else {
        0
    }

$VersionMatches =
    @()

if ($Unambiguous) {

    for ($i = 0; $i -lt $RowCount; $i++) {

        $VersionMatches +=
            [pscustomobject]@{
                RowNumber = $i + 1
                ObjectVersion = [string]$Rows[$i].ObjectVersion
            }
    }
}

$DistinctFromComparisons =
    (
        $Unambiguous -and
        $ComparisonValuesValid -and
        @(
            $ComparisonValues |
            Where-Object {
                $_ -ceq $ObservedVersion
            }
        ).Count -eq 0
    )

$Determination =
    if (
        $ExplicitPresent -and
        $NonEmpty -and
        $Unambiguous -and
        $ComparisonValuesValid -and
        $DistinctFromComparisons
    ) {
        "ESTABLISHED"
    }
    else {
        "NOT_ESTABLISHED"
    }

[pscustomobject]@{
    ImplementationId = $ImplementationId
    SupersedesImplementationId = $SupersedesImplementationId
    HarnessDefinitionId = $HarnessDefinitionId
    RequirementId = $RequirementId
    TestCaseId = $TestCaseId
    VerificationMethodId = $VerificationMethodId
    HarnessMode = $HarnessMode
    AuthorityType = $AuthorityType
    AuthorityBoundary = $AuthorityBoundary
    CandidatePath = $CandidatePath
    CandidateSHA256 = $CandidateSHA256
    CandidateBytes = $CandidateBytes
    RowCount = $RowCount
    ObjectVersionColumnCount = $ObjectVersionColumnCount
    VersionMatchCount = $VersionMatchCount
    VersionMatches = $VersionMatches
    ObservedVersion = $ObservedVersion
    ExplicitPresent = $ExplicitPresent
    NonEmpty = $NonEmpty
    Unambiguous = $Unambiguous
    ComparisonVersions = $ComparisonValues
    ComparisonValuesValid = $ComparisonValuesValid
    DistinctFromComparisons = $DistinctFromComparisons
    Determination = $Determination
}
