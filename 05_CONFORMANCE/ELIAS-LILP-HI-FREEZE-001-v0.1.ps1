param(
    [Parameter(Mandatory=$true)]
    [string]$CandidatePath,

    [Parameter(Mandatory=$true)]
    [string]$StateMarker
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CandidatePath -PathType Leaf)) {
    throw "Candidate artifact does not exist."
}

$Before = Get-Item -LiteralPath $CandidatePath

$Hash1 =
    (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash

$Middle = Get-Item -LiteralPath $CandidatePath

$Hash2 =
    (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash

$After = Get-Item -LiteralPath $CandidatePath

$Stable =
    $Before.Length -eq $Middle.Length -and
    $Middle.Length -eq $After.Length -and
    $Before.LastWriteTimeUtc -eq $Middle.LastWriteTimeUtc -and
    $Middle.LastWriteTimeUtc -eq $After.LastWriteTimeUtc

$Equal =
    $Hash1 -eq $Hash2

$Determination =
    if ($Stable -and $Equal) {
        "PASS"
    }
    else {
        "FAIL"
    }

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-001-v0.1"
    HarnessDefinitionId     = "LILP-HB-FREEZE-001-v0.1"
    CandidatePath           = (Resolve-Path -LiteralPath $CandidatePath).Path
    ByteLength              = $After.Length
    SHA256_1                = $Hash1
    SHA256_2                = $Hash2
    Equality                = $Equal
    ArtifactStable          = $Stable
    StateMarker             = $StateMarker
    Determination           = $Determination
    ExecutionAuthority      = "READ_ONLY_VERIFICATION_ONLY"
}