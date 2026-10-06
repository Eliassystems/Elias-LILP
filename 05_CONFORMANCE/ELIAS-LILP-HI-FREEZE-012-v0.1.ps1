param(
    [Parameter(Mandatory=$true)]
    [string]$ClaimArtifactPath,

    [Parameter(Mandatory=$true)]
    [string]$InternalStatus,

    [Parameter(Mandatory=$true)]
    [string]$ApplicableProfile,

    [Parameter(Mandatory=$true)]
    [string]$ReviewerId,

    [Parameter(Mandatory=$true)]
    [string]$ReviewerAuthority,

    [string]$ExternalAuthorityEvidencePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ClaimArtifactPath -PathType Leaf)) {
    throw "Claim artifact does not exist."
}

$ExternalEvidence = $null

if (
    -not [string]::IsNullOrWhiteSpace($ExternalAuthorityEvidencePath)
) {

    if (-not (Test-Path -LiteralPath $ExternalAuthorityEvidencePath -PathType Leaf)) {
        throw "External-authority evidence path does not exist."
    }

    $ExternalEvidence =
        [pscustomobject][ordered]@{
            Path =
                (Resolve-Path -LiteralPath $ExternalAuthorityEvidencePath).Path

            SHA256 =
                (Get-FileHash -LiteralPath $ExternalAuthorityEvidencePath -Algorithm SHA256).Hash
        }
}

[pscustomobject][ordered]@{
    HarnessImplementationId = "LILP-HI-FREEZE-012-v0.1"
    HarnessDefinitionId     = "LILP-HB-FREEZE-012-v0.1"

    ClaimArtifactPath =
        (Resolve-Path -LiteralPath $ClaimArtifactPath).Path

    ClaimArtifactSHA256 =
        (Get-FileHash -LiteralPath $ClaimArtifactPath -Algorithm SHA256).Hash

    InternalStatus =
        $InternalStatus

    ApplicableProfile =
        $ApplicableProfile

    ReviewerId =
        $ReviewerId

    ReviewerAuthority =
        $ReviewerAuthority

    ReviewCategories =
        @(
            "ISO_ADOPTION",
            "IEC_ADOPTION",
            "REGULATORY_APPROVAL",
            "GOVERNMENT_APPROVAL",
            "INDEPENDENT_CERTIFICATION",
            "INDUSTRY_WIDE_ADOPTION"
        )

    ExternalAuthorityEvidence =
        $ExternalEvidence

    Determination =
        "HUMAN_REVIEW_REQUIRED"

    AutomationAuthority =
        "KEYWORD_SURFACING_EVIDENCE_PRESENTATION_AND_RECORDING_ONLY"

    HumanAuthority =
        "MATERIALLY_CONVEYED_MEANING_AMBIGUITY_AND_EXTERNAL_AUTHORITY_SUFFICIENCY"
}