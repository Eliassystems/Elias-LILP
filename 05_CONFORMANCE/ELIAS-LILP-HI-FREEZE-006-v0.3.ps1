param(
    [Parameter(Mandatory=$true)]
    [string]$CandidatePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CandidatePath -PathType Leaf)) {
    throw "Candidate artifact does not exist."
}

$Lines =
    @(Get-Content -LiteralPath $CandidatePath)

$DetectedMatches =
    [System.Collections.Generic.List[object]]::new()

for ($i = 0; $i -lt $Lines.Count; $i++) {

    $Line = [string]$Lines[$i]

    $PatternType = $null

    if ($Line -match '^\s*PS\s+[^>]*>\s*') {
        $PatternType = "POWERSHELL_PRIMARY_PROMPT"
    }
    elseif ($Line -match '^\s*>>\s*') {
        $PatternType = "POWERSHELL_CONTINUATION_PROMPT"
    }

    if ($null -ne $PatternType) {

        $DetectedMatches.Add(
            [pscustomobject][ordered]@{
                LineNumber  = $i + 1
                PatternType = $PatternType
                Text        = $Line
            }
        )
    }
}

$Determination =
    if ($DetectedMatches.Count -eq 0) {
        "PASS"
    }
    else {
        "REVIEW_REQUIRED"
    }

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-006-v0.3"
    HarnessDefinitionId     = "LILP-HB-FREEZE-006-v0.1"
    CandidatePath           = (Resolve-Path -LiteralPath $CandidatePath).Path
    LinesInspected          = $Lines.Count
    MatchCount              = $DetectedMatches.Count
    Matches                 = @($DetectedMatches)
    Determination           = $Determination
    AuthorityBoundary       = "MATCH_DETECTION_ONLY_CONTEXTUAL_CLEARANCE_REQUIRES_GOVERNED_EVIDENCE"
}