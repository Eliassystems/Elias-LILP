[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CandidatePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$HarnessId             = "LILP-HI-OBJ-004-v0.1"
$HarnessVersion        = "0.1"
$VerificationMethodId  = "LILP-VM-OBJ-004-v0.1"
$RequirementId         = "LILP-REQ-OBJ-004"
$TestCaseId            = "LILP-TC-T02-012"

$RequiredPredicateSet = @(
    "P01_CANDIDATE_ID_PRESENT",
    "P02_CANDIDATE_PROVENANCE_PRESENT",
    "P03_GOVERNANCE_OBJECT_PRESENT",
    "P04_GOVERNANCE_OBJECT_ID_PRESENT",
    "P05_OBJECT_IDENTITY_MATERIAL_PRESENT",
    "P06_LIFECYCLE_CONTEXT_PRESENT",
    "P07_PREDECESSOR_EXISTENCE_STATE_PRESENT",
    "P08_PREDECESSOR_EXISTENCE_STATE_EXPLICIT_AND_ALLOWED",
    "P09_PREDECESSOR_EXISTENCE_SOURCE_PRESENT",
    "P10_REQUIRED_PREDECESSOR_RELATIONSHIP_REPRESENTATION_PRESENT_WHEN_EXISTS",
    "P11_PREDECESSOR_RELATIONSHIP_ATTRIBUTABLE_AND_NON_CONTRADICTORY",
    "P12_NO_PREDECESSOR_INFERENCE_OR_RETROSPECTIVE_RECONSTRUCTION_REQUIRED"
)

$AllowedPredecessorExistenceStates = @(
    "EXISTS",
    "NONE",
    "UNRESOLVED"
)

function Get-DirectPropertyValue {

    param(
        [object]$Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    $Property =
        $Object.PSObject.Properties[$Name]

    if ($null -eq $Property) {
        return $null
    }

    return $Property.Value
}

function Test-ExplicitValue {

    param(
        [object]$Value
    )

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [string]) {
        return -not [string]::IsNullOrWhiteSpace($Value)
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return $Value.Count -gt 0
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        return @($Value.PSObject.Properties).Count -gt 0
    }

    if (
        $Value -is [System.Collections.IEnumerable] -and
        -not ($Value -is [string])
    ) {
        return @($Value).Count -gt 0
    }

    return $true
}

$FileExists =
    Test-Path -LiteralPath $CandidatePath -PathType Leaf

$CandidateSHA256 =
    $null

$Candidate =
    $null

$ParseSucceeded =
    $false

$ParseError =
    $null

if ($FileExists) {

    try {

        $CandidateSHA256 =
            (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash

        $RawCandidate =
            Get-Content -LiteralPath $CandidatePath -Raw -ErrorAction Stop

        $Candidate =
            $RawCandidate |
            ConvertFrom-Json -ErrorAction Stop

        $ParseSucceeded =
            $true
    }
    catch {

        $ParseError =
            $_.Exception.Message
    }
}

$CandidateId =
    Get-DirectPropertyValue $Candidate "CandidateId"

$CandidateProvenance =
    Get-DirectPropertyValue $Candidate "CandidateProvenance"

$GovernanceObject =
    Get-DirectPropertyValue $Candidate "GovernanceObject"

$GovernanceObjectId =
    Get-DirectPropertyValue $GovernanceObject "ObjectId"

$ObjectIdentityMaterial =
    Get-DirectPropertyValue $GovernanceObject "IdentityMaterial"

$LifecycleContext =
    Get-DirectPropertyValue $GovernanceObject "LifecycleContext"

$PredecessorExistence =
    Get-DirectPropertyValue $GovernanceObject "PredecessorExistence"

$PredecessorExistenceStatus =
    Get-DirectPropertyValue $PredecessorExistence "Status"

$PredecessorExistenceSource =
    Get-DirectPropertyValue $PredecessorExistence "Source"

$PredecessorRelationship =
    Get-DirectPropertyValue $GovernanceObject "PredecessorRelationship"

$PredecessorIdentifier =
    Get-DirectPropertyValue $PredecessorRelationship "Identifier"

$PredecessorReference =
    Get-DirectPropertyValue $PredecessorRelationship "Reference"

$PredecessorEquivalentRepresentation =
    Get-DirectPropertyValue $PredecessorRelationship "EquivalentRepresentation"

$PredecessorRelationshipSource =
    Get-DirectPropertyValue $PredecessorRelationship "Source"

$RelationshipAttributedObjectId =
    Get-DirectPropertyValue $PredecessorRelationship "AttributedObjectId"

$ExplicitRelationshipRepresentations =
    @()

if (Test-ExplicitValue $PredecessorIdentifier) {
    $ExplicitRelationshipRepresentations +=
        [string]$PredecessorIdentifier
}

if (Test-ExplicitValue $PredecessorReference) {
    $ExplicitRelationshipRepresentations +=
        [string]$PredecessorReference
}

if (Test-ExplicitValue $PredecessorEquivalentRepresentation) {
    $ExplicitRelationshipRepresentations +=
        [string]$PredecessorEquivalentRepresentation
}

$AnyRelationshipEvidence =
    (
        (Test-ExplicitValue $PredecessorIdentifier) -or
        (Test-ExplicitValue $PredecessorReference) -or
        (Test-ExplicitValue $PredecessorEquivalentRepresentation) -or
        (Test-ExplicitValue $PredecessorRelationshipSource) -or
        (Test-ExplicitValue $RelationshipAttributedObjectId)
    )

$P01 =
    $ParseSucceeded -and
    (Test-ExplicitValue $CandidateId)

$P02 =
    $ParseSucceeded -and
    (Test-ExplicitValue $CandidateProvenance)

$P03 =
    $ParseSucceeded -and
    (Test-ExplicitValue $GovernanceObject)

$P04 =
    $P03 -and
    (Test-ExplicitValue $GovernanceObjectId)

$P05 =
    $P03 -and
    (Test-ExplicitValue $ObjectIdentityMaterial)

$P06 =
    $P03 -and
    (Test-ExplicitValue $LifecycleContext)

$P07 =
    $P03 -and
    (Test-ExplicitValue $PredecessorExistenceStatus)

$P08 =
    $P07 -and
    ($AllowedPredecessorExistenceStates -ccontains [string]$PredecessorExistenceStatus)

$P09 =
    $P08 -and
    (Test-ExplicitValue $PredecessorExistenceSource)

$P10 =
    $false

if ($P08) {

    if ([string]$PredecessorExistenceStatus -ceq "EXISTS") {

        $P10 =
            $ExplicitRelationshipRepresentations.Count -gt 0
    }
    else {

        $P10 =
            $true
    }
}

$P11 =
    $false

if ($P08) {

    switch -CaseSensitive ([string]$PredecessorExistenceStatus) {

        "EXISTS" {

            $P11 =
                ($ExplicitRelationshipRepresentations.Count -gt 0) -and
                (Test-ExplicitValue $PredecessorRelationshipSource) -and
                (Test-ExplicitValue $RelationshipAttributedObjectId) -and
                (Test-ExplicitValue $GovernanceObjectId) -and
                ([string]$RelationshipAttributedObjectId -ceq [string]$GovernanceObjectId)
        }

        "NONE" {

            $P11 =
                -not $AnyRelationshipEvidence
        }

        "UNRESOLVED" {

            $P11 =
                $true
        }
    }
}

$P12 =
    $false

if ($P08) {

    switch -CaseSensitive ([string]$PredecessorExistenceStatus) {

        "EXISTS" {

            $P12 =
                ($ExplicitRelationshipRepresentations.Count -gt 0) -and
                (Test-ExplicitValue $PredecessorRelationshipSource) -and
                (Test-ExplicitValue $RelationshipAttributedObjectId) -and
                (Test-ExplicitValue $GovernanceObjectId)
        }

        "NONE" {

            $P12 =
                (Test-ExplicitValue $PredecessorExistenceSource) -and
                (-not $AnyRelationshipEvidence)
        }

        "UNRESOLVED" {

            $P12 =
                $true
        }
    }
}

$PredicateObservations =
    [ordered]@{
        P01_CANDIDATE_ID_PRESENT =
            [bool]$P01

        P02_CANDIDATE_PROVENANCE_PRESENT =
            [bool]$P02

        P03_GOVERNANCE_OBJECT_PRESENT =
            [bool]$P03

        P04_GOVERNANCE_OBJECT_ID_PRESENT =
            [bool]$P04

        P05_OBJECT_IDENTITY_MATERIAL_PRESENT =
            [bool]$P05

        P06_LIFECYCLE_CONTEXT_PRESENT =
            [bool]$P06

        P07_PREDECESSOR_EXISTENCE_STATE_PRESENT =
            [bool]$P07

        P08_PREDECESSOR_EXISTENCE_STATE_EXPLICIT_AND_ALLOWED =
            [bool]$P08

        P09_PREDECESSOR_EXISTENCE_SOURCE_PRESENT =
            [bool]$P09

        P10_REQUIRED_PREDECESSOR_RELATIONSHIP_REPRESENTATION_PRESENT_WHEN_EXISTS =
            [bool]$P10

        P11_PREDECESSOR_RELATIONSHIP_ATTRIBUTABLE_AND_NON_CONTRADICTORY =
            [bool]$P11

        P12_NO_PREDECESSOR_INFERENCE_OR_RETROSPECTIVE_RECONSTRUCTION_REQUIRED =
            [bool]$P12
    }

$AbsentPredicates =
    @()

$AmbiguousPredicates =
    @()

$ContradictoryPredicates =
    @()

if (-not $P01) {
    $AbsentPredicates += "P01_CANDIDATE_ID_PRESENT"
}

if (-not $P02) {
    $AbsentPredicates += "P02_CANDIDATE_PROVENANCE_PRESENT"
}

if (-not $P03) {
    $AbsentPredicates += "P03_GOVERNANCE_OBJECT_PRESENT"
}

if (-not $P04) {
    $AbsentPredicates += "P04_GOVERNANCE_OBJECT_ID_PRESENT"
}

if (-not $P05) {
    $AbsentPredicates += "P05_OBJECT_IDENTITY_MATERIAL_PRESENT"
}

if (-not $P06) {
    $AbsentPredicates += "P06_LIFECYCLE_CONTEXT_PRESENT"
}

if (-not $P07) {

    $AbsentPredicates +=
        "P07_PREDECESSOR_EXISTENCE_STATE_PRESENT"
}
elseif (-not $P08) {

    $AmbiguousPredicates +=
        "P08_PREDECESSOR_EXISTENCE_STATE_EXPLICIT_AND_ALLOWED"
}

if (-not $P09) {

    $AbsentPredicates +=
        "P09_PREDECESSOR_EXISTENCE_SOURCE_PRESENT"
}

if (
    $P08 -and
    [string]$PredecessorExistenceStatus -ceq "EXISTS"
) {

    if (-not $P10) {

        $AbsentPredicates +=
            "P10_REQUIRED_PREDECESSOR_RELATIONSHIP_REPRESENTATION_PRESENT_WHEN_EXISTS"
    }

    if (-not (Test-ExplicitValue $PredecessorRelationshipSource)) {

        $AbsentPredicates +=
            "P11_PREDECESSOR_RELATIONSHIP_ATTRIBUTABLE_AND_NON_CONTRADICTORY"
    }
    elseif (
        (Test-ExplicitValue $RelationshipAttributedObjectId) -and
        (Test-ExplicitValue $GovernanceObjectId) -and
        ([string]$RelationshipAttributedObjectId -cne [string]$GovernanceObjectId)
    ) {

        $ContradictoryPredicates +=
            "P11_PREDECESSOR_RELATIONSHIP_ATTRIBUTABLE_AND_NON_CONTRADICTORY"
    }
    elseif (-not $P11) {

        $AbsentPredicates +=
            "P11_PREDECESSOR_RELATIONSHIP_ATTRIBUTABLE_AND_NON_CONTRADICTORY"
    }
}

if (
    $P08 -and
    [string]$PredecessorExistenceStatus -ceq "NONE" -and
    $AnyRelationshipEvidence
) {

    $ContradictoryPredicates +=
        "P11_PREDECESSOR_RELATIONSHIP_ATTRIBUTABLE_AND_NON_CONTRADICTORY"
}

if (-not $P12) {

    $AbsentPredicates +=
        "P12_NO_PREDECESSOR_INFERENCE_OR_RETROSPECTIVE_RECONSTRUCTION_REQUIRED"
}

$AllPredicatesSatisfied =
    $true

foreach ($PredicateName in $RequiredPredicateSet) {

    if (-not [bool]$PredicateObservations[$PredicateName]) {
        $AllPredicatesSatisfied = $false
        break
    }
}

$EligibleDeterminationBranch =
    (
        [string]$PredecessorExistenceStatus -ceq "EXISTS" -or
        [string]$PredecessorExistenceStatus -ceq "NONE"
    )

$Determination =
    "NOT_ESTABLISHED"

if (
    $AllPredicatesSatisfied -and
    $EligibleDeterminationBranch
) {
    $Determination =
        "ESTABLISHED"
}

$PredecessorRelationshipRepresentation =
    [ordered]@{
        Identifier =
            $PredecessorIdentifier

        Reference =
            $PredecessorReference

        EquivalentRepresentation =
            $PredecessorEquivalentRepresentation
    }

$InspectionRecord =
    [ordered]@{
        FileExists =
            [bool]$FileExists

        ParseSucceeded =
            [bool]$ParseSucceeded

        ParseError =
            $ParseError

        PredecessorBranch =
            $PredecessorExistenceStatus

        RelationshipEvidencePresent =
            [bool]$AnyRelationshipEvidence

        RelationshipRepresentationCount =
            [int]$ExplicitRelationshipRepresentations.Count

        DirectEvidenceOnly =
            $true

        FilenameSemanticAuthority =
            "NONE"

        PathSemanticAuthority =
            "NONE"

        FilesystemMetadataAuthority =
            "NONE"

        ChronologyInferenceAuthority =
            "NONE"

        SemanticSimilarityAuthority =
            "NONE"

        SystemClockAuthority =
            "NONE"

        ExternalLookupAuthority =
            "NONE"

        RetrospectiveReconstructionAuthority =
            "NONE"

        AbsenceEstablishesNone =
            $false

        UnknownPredecessorStateFailsClosed =
            $true
    }

$Output =
    [ordered]@{
        HarnessId =
            $HarnessId

        HarnessVersion =
            $HarnessVersion

        VerificationMethodId =
            $VerificationMethodId

        RequirementId =
            $RequirementId

        TestCaseId =
            $TestCaseId

        CandidatePath =
            $CandidatePath

        CandidateSHA256 =
            $CandidateSHA256

        CandidateId =
            $CandidateId

        CandidateProvenance =
            $CandidateProvenance

        GovernanceObjectId =
            $GovernanceObjectId

        PredecessorExistenceStatus =
            $PredecessorExistenceStatus

        PredecessorExistenceSource =
            $PredecessorExistenceSource

        PredecessorRelationshipRepresentation =
            $PredecessorRelationshipRepresentation

        PredecessorRelationshipSource =
            $PredecessorRelationshipSource

        RelationshipAttributedObjectId =
            $RelationshipAttributedObjectId

        RequiredPredicateSet =
            $RequiredPredicateSet

        PredicateObservations =
            $PredicateObservations

        AbsentPredicates =
            @($AbsentPredicates | Sort-Object -Unique)

        AmbiguousPredicates =
            @($AmbiguousPredicates | Sort-Object -Unique)

        ContradictoryPredicates =
            @($ContradictoryPredicates | Sort-Object -Unique)

        Determination =
            $Determination

        InspectionRecord =
            $InspectionRecord
    }

$Output |
    ConvertTo-Json -Depth 12
