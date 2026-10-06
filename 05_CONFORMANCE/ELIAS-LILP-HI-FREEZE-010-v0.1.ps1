param(
    [Parameter(Mandatory=$true)]
    [string]$CandidatePath,

    [Parameter(Mandatory=$true)]
    [string]$LexiconPath,

    [Parameter(Mandatory=$true)]
    [string]$MaterialTermInventoryPath,

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
    $MaterialTermInventoryPath
)) {

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required review input does not exist: $Path"
    }
}

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-010-v0.1"
    HarnessDefinitionId     = "LILP-HB-FREEZE-010-v0.1"

    CandidatePath =
        (Resolve-Path -LiteralPath $CandidatePath).Path

    CandidateSHA256 =
        (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash

    LexiconPath =
        (Resolve-Path -LiteralPath $LexiconPath).Path

    LexiconSHA256 =
        (Get-FileHash -LiteralPath $LexiconPath -Algorithm SHA256).Hash

    MaterialTermInventoryPath =
        (Resolve-Path -LiteralPath $MaterialTermInventoryPath).Path

    MaterialTermInventorySHA256 =
        (Get-FileHash -LiteralPath $MaterialTermInventoryPath -Algorithm SHA256).Hash

    ReviewerId =
        $ReviewerId

    ReviewerAuthority =
        $ReviewerAuthority

    RequiredHumanClassifications =
        @(
            "COMPATIBLE",
            "EXPLICITLY_NARROWED",
            "MATERIAL_CONFLICT"
        )

    Determination =
        "HUMAN_REVIEW_REQUIRED"

    AutomationAuthority =
        "EVIDENCE_PRESENTATION_AND_RECORDING_ONLY"

    HumanAuthority =
        "SEMANTIC_COMPATIBILITY_MATERIALITY_AND_NORMATIVE_CONFLICT"
}