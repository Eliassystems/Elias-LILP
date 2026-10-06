param(
    [Parameter(Mandatory=$true)]
    [string]$CandidatePath,

    [Parameter(Mandatory=$true)]
    [string[]]$ComparisonVersion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CandidatePath -PathType Leaf)) {
    throw "Candidate artifact does not exist."
}

if ($ComparisonVersion.Count -eq 0) {
    throw "At least one governed comparison version is required."
}

$Candidate = Get-Item -LiteralPath $CandidatePath
$CandidateSHA256 =
    (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash

$Lines =
    @(Get-Content -LiteralPath $CandidatePath)

$VersionMatches =
    [System.Collections.Generic.List[object]]::new()

for ($i = 0; $i -lt $Lines.Count; $i++) {

    $Line = [string]$Lines[$i]

    $Match =
        [regex]::Match(
            $Line,
            '^\s*(?:"?)(?<Field>Version|ObjectVersion|Object Version|ArtifactVersion|Artifact Version|DocumentVersion|Document Version|SpecificationVersion|Specification Version|StandardVersion|Standard Version)(?:"?)\s*[:=]\s*["'']?(?<Value>[A-Za-z0-9][A-Za-z0-9._-]*)["'']?\s*[,;]?\s*$',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

    if ($Match.Success) {

        $VersionMatches.Add(
            [pscustomobject][ordered]@{
                LineNumber = $i + 1
                FieldName  = $Match.Groups["Field"].Value
                Value      = $Match.Groups["Value"].Value
                Text       = $Line
            }
        )
    }
}

$ObservedVersion =
    if ($VersionMatches.Count -eq 1) {
        [string]$VersionMatches[0].Value
    }
    else {
        $null
    }

$ExplicitPresent =
    $VersionMatches.Count -gt 0

$NonEmpty =
    $VersionMatches.Count -eq 1 -and
    -not [string]::IsNullOrWhiteSpace($ObservedVersion)

$Unambiguous =
    $VersionMatches.Count -eq 1

$ComparisonValues =
    @(
        $ComparisonVersion |
        ForEach-Object {
            [string]$_
        }
    )

$ComparisonValuesValid =
    @(
        $ComparisonValues |
        Where-Object {
            [string]::IsNullOrWhiteSpace($_)
        }
    ).Count -eq 0

$DistinctFromComparisons =
    $NonEmpty -and
    $ComparisonValuesValid -and
    @(
        $ComparisonValues |
        Where-Object {
            $_ -ceq $ObservedVersion
        }
    ).Count -eq 0

$Determination =
    if (-not $ExplicitPresent) {
        "NOT_ESTABLISHED"
    }
    elseif (-not $Unambiguous -or -not $NonEmpty) {
        "NOT_ESTABLISHED"
    }
    elseif (-not $ComparisonValuesValid) {
        "NOT_ESTABLISHED"
    }
    elseif (-not $DistinctFromComparisons) {
        "FAIL"
    }
    else {
        "MECHANICAL_VERSION_IDENTITY_ESTABLISHED"
    }

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-OBJ-002-v0.1"
    HarnessDefinitionId     = "LILP-HB-OBJ-002-v0.1"
    CandidatePath           = (Resolve-Path -LiteralPath $CandidatePath).Path
    CandidateSHA256         = $CandidateSHA256
    CandidateBytes          = $Candidate.Length
    LinesInspected          = $Lines.Count
    VersionMatchCount       = $VersionMatches.Count
    VersionMatches          = @($VersionMatches)
    ObservedVersion         = $ObservedVersion
    ExplicitPresent         = $ExplicitPresent
    NonEmpty                = $NonEmpty
    Unambiguous             = $Unambiguous
    ComparisonVersions      = @($ComparisonValues)
    ComparisonValuesValid   = $ComparisonValuesValid
    DistinctFromComparisons = $DistinctFromComparisons
    Determination           = $Determination
    AuthorityBoundary       = "EXPLICIT_VERSION_METADATA_EXTRACTION_AND_EXACT_COMPARISON_ONLY_NO_SEMANTIC_OR_GOVERNANCE_INFERENCE"
}
