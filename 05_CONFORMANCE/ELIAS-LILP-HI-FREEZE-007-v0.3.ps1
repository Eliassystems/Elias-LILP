param(
    [Parameter(Mandatory=$true)]
    [string]$BindingRecordPath,

    [Parameter(Mandatory=$true)]
    [string]$BindingProvenancePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ExpectedCandidateSHA256 =
    "076EE05F6441EA1A41F30006614AB0343E66E809A000B7509BDFF0CF729F5537"

$ExpectedIdentifier =
    "ELIAS-LILP-LEX-001"

$ExpectedVersion =
    "v0.1"

$ExpectedLexiconSHA256 =
    "144EFB9CAAB7A0F0537A84704626AC58C5659A0B50F92AA64086B07918E63488"

$ExpectedFreezeReceiptId =
    "ELIAS-LILP-RECEIPT-0003"

$ExpectedFreezeReceiptSHA256 =
    "EA60056D55EEBB8AF990C5261FA367727897DA62BD8AC4D8CD43614769221DE0"

foreach ($Path in @(
    $BindingRecordPath,
    $BindingProvenancePath
)) {

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required governed evidence does not exist: $Path"
    }
}

$BindingRecordSHA256 =
    (Get-FileHash -LiteralPath $BindingRecordPath -Algorithm SHA256).Hash

$BindingProvenanceSHA256 =
    (Get-FileHash -LiteralPath $BindingProvenancePath -Algorithm SHA256).Hash

$BindingRaw =
    Get-Content -LiteralPath $BindingRecordPath -Raw

$ProvenanceRaw =
    Get-Content -LiteralPath $BindingProvenancePath -Raw

$CandidateIdentityEqual =
    $BindingRecordSHA256 -ceq $ExpectedCandidateSHA256

$ProvenanceIdentityEqual =
    $BindingProvenanceSHA256 -ceq $ExpectedFreezeReceiptSHA256

# ----------------------------------------------------------------------
# Normative lexicon binding.
#
# This intentionally follows the governed representation actually present
# in the frozen standard. It does not require retrospective key=value
# reformulation of the frozen evidence.
# ----------------------------------------------------------------------

$NormativeBindingPattern =
    '(?ims)^\s*Lexicon:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedIdentifier) +
    '\s+' +
    [regex]::Escape($ExpectedVersion) +
    '\s+FROZEN BASELINE\s*\r?\n\s*SHA-256:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedLexiconSHA256) +
    '\s*\r?\n\s*Freeze Receipt:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedFreezeReceiptId) +
    '\s*\r?\n\s*Freeze Receipt SHA-256:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedFreezeReceiptSHA256)

$NormativeBindingMatches =
    [regex]::Matches(
        $BindingRaw,
        $NormativeBindingPattern
    )

$NormativeBindingExact =
    $NormativeBindingMatches.Count -eq 1

# ----------------------------------------------------------------------
# Requirement-side continuity statement.
# ----------------------------------------------------------------------

$RequirementBindingPattern =
    '(?ims)^\s*LILP-REQ-FREEZE-007\s*\r?\n\s*' +
    'The frozen lexicon binding SHALL continue to identify:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedIdentifier) +
    '\s+' +
    [regex]::Escape($ExpectedVersion) +
    '\s*\r?\n\s*SHA-256:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedLexiconSHA256)

$RequirementBindingMatches =
    [regex]::Matches(
        $BindingRaw,
        $RequirementBindingPattern
    )

$RequirementBindingExact =
    $RequirementBindingMatches.Count -eq 1

# ----------------------------------------------------------------------
# Provenance receipt identity fields.
# ----------------------------------------------------------------------

$ProvenanceIdentityPattern =
    '(?ims)^\s*Document ID:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedIdentifier) +
    '\s*\r?\n\s*Version:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedVersion)

$ProvenanceIdentityMatches =
    [regex]::Matches(
        $ProvenanceRaw,
        $ProvenanceIdentityPattern
    )

$ProvenanceIdentityFieldsExact =
    $ProvenanceIdentityMatches.Count -eq 1

$ProvenanceHashPattern =
    '(?ims)^\s*SHA-256:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedLexiconSHA256)

$ProvenanceHashMatches =
    [regex]::Matches(
        $ProvenanceRaw,
        $ProvenanceHashPattern
    )

$ProvenanceHashFieldExact =
    $ProvenanceHashMatches.Count -eq 1

$FreezeDeterminationPattern =
    '(?ims)The exact verified byte sequence identified by:\s*\r?\n\s*' +
    [regex]::Escape($ExpectedLexiconSHA256) +
    '\s*\r?\n\s*is established as the\s+' +
    [regex]::Escape($ExpectedIdentifier) +
    '\s+' +
    [regex]::Escape($ExpectedVersion) +
    '\s+FROZEN BASELINE\.'

$FreezeDeterminationMatches =
    [regex]::Matches(
        $ProvenanceRaw,
        $FreezeDeterminationPattern
    )

$FreezeDeterminationExact =
    $FreezeDeterminationMatches.Count -eq 1

$MechanicalPass =
    $CandidateIdentityEqual -and
    $ProvenanceIdentityEqual -and
    $NormativeBindingExact -and
    $RequirementBindingExact -and
    $ProvenanceIdentityFieldsExact -and
    $ProvenanceHashFieldExact -and
    $FreezeDeterminationExact

$Determination =
    if ($MechanicalPass) {
        "PASS"
    }
    else {
        "FAIL"
    }

[pscustomobject][ordered]@{

    HarnessImplementationId =
        "LILP-HI-FREEZE-007-v0.3"

    SupersedesImplementationId =
        "LILP-HI-FREEZE-007-v0.2"

    HarnessDefinitionId =
        "LILP-HB-FREEZE-007-v0.1"

    RequirementId =
        "LILP-REQ-FREEZE-007"

    TestCaseId =
        "LILP-TC-T14-014"

    VerificationMethodId =
        "LILP-VM-FREEZE-007-v0.1"

    BindingRecordPath =
        (Resolve-Path -LiteralPath $BindingRecordPath).Path

    BindingRecordSHA256 =
        $BindingRecordSHA256

    ExpectedCandidateSHA256 =
        $ExpectedCandidateSHA256

    CandidateIdentityEqual =
        $CandidateIdentityEqual

    BindingProvenancePath =
        (Resolve-Path -LiteralPath $BindingProvenancePath).Path

    BindingProvenanceSHA256 =
        $BindingProvenanceSHA256

    ExpectedFreezeReceiptSHA256 =
        $ExpectedFreezeReceiptSHA256

    ProvenanceIdentityEqual =
        $ProvenanceIdentityEqual

    ExpectedIdentifier =
        $ExpectedIdentifier

    ExpectedVersion =
        $ExpectedVersion

    ExpectedLexiconSHA256 =
        $ExpectedLexiconSHA256

    ExpectedFreezeReceiptId =
        $ExpectedFreezeReceiptId

    NormativeBindingMatchCount =
        $NormativeBindingMatches.Count

    NormativeBindingExact =
        $NormativeBindingExact

    RequirementBindingMatchCount =
        $RequirementBindingMatches.Count

    RequirementBindingExact =
        $RequirementBindingExact

    ProvenanceIdentityMatchCount =
        $ProvenanceIdentityMatches.Count

    ProvenanceIdentityFieldsExact =
        $ProvenanceIdentityFieldsExact

    ProvenanceHashMatchCount =
        $ProvenanceHashMatches.Count

    ProvenanceHashFieldExact =
        $ProvenanceHashFieldExact

    FreezeDeterminationMatchCount =
        $FreezeDeterminationMatches.Count

    FreezeDeterminationExact =
        $FreezeDeterminationExact

    MechanicalPass =
        $MechanicalPass

    Determination =
        $Determination

    AuthorityType =
        "DETERMINISTIC_MECHANICAL"

    AuthorityBoundary =
        "NO_HUMAN_SEMANTIC_DETERMINATION"

    ExecutionAuthority =
        "NONE"

    ConsequenceExecuted =
        $false

    ResultScope =
        "LILP-TC-T14-014_MECHANICAL_ONLY"
}
