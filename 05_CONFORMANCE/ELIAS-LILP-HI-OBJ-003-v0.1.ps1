param(
    [Parameter(Mandatory = $true)]
    [string]$CandidatePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$HarnessId = "LILP-HI-OBJ-003-v0.1"
$HarnessVersion = "v0.1"
$RequirementId = "LILP-REQ-OBJ-003"
$TestCaseId = "LILP-TC-T02-007"
$VerificationMethodId = "LILP-VM-OBJ-003-v0.1"
$DesignSHA256 = "279091F276F834F234EDF0BBD1E9044C2D11EA3476F82A80463DC01D6A510285"
$ConstructionGovernanceSHA256 = "C3BD4869CB504B31940E79C7A20F4C2A300203D94A5E735B673E4E9B9E4B2DBA"

$RequiredPredicateSet = @(
    "P01_CANDIDATE_ID_PRESENT",
    "P02_CANDIDATE_PROVENANCE_PRESENT",
    "P03_GOVERNANCE_OBJECT_PRESENT",
    "P04_OBJECT_IDENTITY_MATERIAL_PRESENT",
    "P05_DECLARED_CONSEQUENTIAL_USE_PRESENT",
    "P06_TEMPORAL_CONTEXT_PRESENT",
    "P07_TEMPORAL_CONTEXT_KIND_EXPLICIT_AND_ALLOWED",
    "P08_TEMPORAL_CONTEXT_VALUE_PRESENT",
    "P09_TEMPORAL_CONTEXT_SOURCE_PRESENT",
    "P10_NO_TEMPORAL_CONTEXT_INFERENCE_REQUIRED"
)

$AllowedTemporalKinds = @(
    "CREATION_TIME",
    "APPLICABILITY_TIME",
    "TEMPORAL_STATE"
)

$ProhibitedTemporalSources = @(
    "FILENAME",
    "PATH",
    "FILESYSTEM",
    "FILESYSTEM_TIMESTAMP",
    "SYSTEM_CLOCK",
    "CURRENT_SYSTEM_TIME",
    "EXTERNAL_LOOKUP"
)

function Get-ExplicitProperty {

    param(
        [object]$Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return [pscustomobject]@{
            Exists = $false
            Value  = $null
        }
    }

    $Property = $Object.PSObject.Properties[$Name]

    if ($null -eq $Property) {
        return [pscustomobject]@{
            Exists = $false
            Value  = $null
        }
    }

    return [pscustomobject]@{
        Exists = $true
        Value  = $Property.Value
    }
}

function Test-ExplicitValue {

    param(
        [object]$Value
    )

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [string]) {
        return (-not [string]::IsNullOrWhiteSpace($Value))
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return ($Value.Count -gt 0)
    }

    if (
        $Value -is [System.Collections.IEnumerable] -and
        -not ($Value -is [string])
    ) {
        return (@($Value).Count -gt 0)
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        return (@($Value.PSObject.Properties).Count -gt 0)
    }

    return $true
}

function Test-ExplicitScalar {

    param(
        [object]$Value
    )

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [string]) {
        return (-not [string]::IsNullOrWhiteSpace($Value))
    }

    if ($Value -is [System.ValueType]) {
        return $true
    }

    return $false
}

function New-PredicateObservation {

    param(
        [string]$Predicate,
        [bool]$Satisfied,
        [object]$Observed,
        [string]$Reason
    )

    return [pscustomobject][ordered]@{
        Predicate = $Predicate
        Satisfied = $Satisfied
        Observed  = $Observed
        Reason    = $Reason
    }
}

function Write-BoundedResult {

    param(
        [string]$ResolvedCandidatePath,
        [object]$CandidateSHA256,
        [object]$CandidateId,
        [object]$CandidateProvenance,
        [object[]]$PredicateObservations,
        [string[]]$AbsentPredicates,
        [string[]]$AmbiguousPredicates,
        [string[]]$ContradictoryPredicates,
        [string]$Determination,
        [object]$InspectionRecord
    )

    $Result = [pscustomobject][ordered]@{
        HarnessId               = $HarnessId
        HarnessVersion          = $HarnessVersion
        VerificationMethodId    = $VerificationMethodId
        RequirementId           = $RequirementId
        TestCaseId              = $TestCaseId
        CandidatePath           = $ResolvedCandidatePath
        CandidateSHA256         = $CandidateSHA256
        CandidateId             = $CandidateId
        CandidateProvenance     = $CandidateProvenance
        RequiredPredicateSet    = @($RequiredPredicateSet)
        PredicateObservations   = @($PredicateObservations)
        AbsentPredicates        = @($AbsentPredicates)
        AmbiguousPredicates     = @($AmbiguousPredicates)
        ContradictoryPredicates = @($ContradictoryPredicates)
        Determination           = $Determination
        InspectionRecord        = $InspectionRecord
    }

    $Result |
        ConvertTo-Json -Depth 12 |
        Write-Output
}

$ResolvedCandidatePath = [System.IO.Path]::GetFullPath($CandidatePath)

if (-not [System.IO.File]::Exists($ResolvedCandidatePath)) {

    $Observations = @()

    foreach ($Predicate in $RequiredPredicateSet) {
        $Observations += New-PredicateObservation `
            -Predicate $Predicate `
            -Satisfied $false `
            -Observed $null `
            -Reason "Designated candidate file is absent; predicate cannot be directly established."
    }

    Write-BoundedResult `
        -ResolvedCandidatePath $ResolvedCandidatePath `
        -CandidateSHA256 $null `
        -CandidateId $null `
        -CandidateProvenance $null `
        -PredicateObservations $Observations `
        -AbsentPredicates @($RequiredPredicateSet) `
        -AmbiguousPredicates @() `
        -ContradictoryPredicates @() `
        -Determination "NOT_ESTABLISHED" `
        -InspectionRecord ([pscustomobject][ordered]@{
            ReadOnlyInspection             = $true
            CandidateExists                = $false
            JsonParseSucceeded             = $false
            CandidateContentAuthorityOnly  = $true
            FilenameSemanticAuthorityUsed  = $false
            FilesystemMetadataAuthorityUsed = $false
            SystemClockAuthorityUsed       = $false
            ExternalLookupAuthorityUsed    = $false
            InferenceSourcesUsed           = @()
            DesignSHA256                   = $DesignSHA256
            ConstructionGovernanceSHA256   = $ConstructionGovernanceSHA256
            Finding                        = "Designated candidate file absent."
        })

    return
}

$CandidateSHA256 =
    (Get-FileHash -LiteralPath $ResolvedCandidatePath -Algorithm SHA256).Hash

$CandidateRaw =
    [System.IO.File]::ReadAllText($ResolvedCandidatePath)

try {
    $Candidate = $CandidateRaw | ConvertFrom-Json
}
catch {

    $Observations = @()

    foreach ($Predicate in $RequiredPredicateSet) {
        $Observations += New-PredicateObservation `
            -Predicate $Predicate `
            -Satisfied $false `
            -Observed $null `
            -Reason "Candidate content is not valid parseable JSON; direct predicate inspection cannot be completed."
    }

    Write-BoundedResult `
        -ResolvedCandidatePath $ResolvedCandidatePath `
        -CandidateSHA256 $CandidateSHA256 `
        -CandidateId $null `
        -CandidateProvenance $null `
        -PredicateObservations $Observations `
        -AbsentPredicates @() `
        -AmbiguousPredicates @($RequiredPredicateSet) `
        -ContradictoryPredicates @() `
        -Determination "NOT_ESTABLISHED" `
        -InspectionRecord ([pscustomobject][ordered]@{
            ReadOnlyInspection              = $true
            CandidateExists                 = $true
            JsonParseSucceeded              = $false
            CandidateContentAuthorityOnly   = $true
            FilenameSemanticAuthorityUsed   = $false
            FilesystemMetadataAuthorityUsed = $false
            SystemClockAuthorityUsed        = $false
            ExternalLookupAuthorityUsed     = $false
            InferenceSourcesUsed            = @()
            DesignSHA256                    = $DesignSHA256
            ConstructionGovernanceSHA256    = $ConstructionGovernanceSHA256
            Finding                         = "Candidate JSON parsing failed."
        })

    return
}

$CandidateIdState =
    Get-ExplicitProperty -Object $Candidate -Name "CandidateId"

$CandidateProvenanceState =
    Get-ExplicitProperty -Object $Candidate -Name "CandidateProvenance"

$GovernanceObjectState =
    Get-ExplicitProperty -Object $Candidate -Name "GovernanceObject"

$ObjectIdentityMaterialState =
    Get-ExplicitProperty -Object $Candidate -Name "ObjectIdentityMaterial"

$DeclaredConsequentialUseState =
    Get-ExplicitProperty -Object $Candidate -Name "DeclaredConsequentialUse"

$TemporalContextState =
    Get-ExplicitProperty -Object $Candidate -Name "TemporalContext"

$P01 =
    $CandidateIdState.Exists -and
    (Test-ExplicitValue $CandidateIdState.Value)

$P02 =
    $CandidateProvenanceState.Exists -and
    (Test-ExplicitValue $CandidateProvenanceState.Value)

$P03 =
    $GovernanceObjectState.Exists -and
    (Test-ExplicitValue $GovernanceObjectState.Value)

$P04 =
    $ObjectIdentityMaterialState.Exists -and
    (Test-ExplicitValue $ObjectIdentityMaterialState.Value)

$P05 =
    $DeclaredConsequentialUseState.Exists -and
    (Test-ExplicitValue $DeclaredConsequentialUseState.Value)

$TemporalContextIsObject =
    $TemporalContextState.Exists -and
    $null -ne $TemporalContextState.Value -and
    ($TemporalContextState.Value -is [System.Management.Automation.PSCustomObject])

$P06 =
    $TemporalContextIsObject

$TemporalKindState =
    if ($TemporalContextIsObject) {
        Get-ExplicitProperty -Object $TemporalContextState.Value -Name "Kind"
    }
    else {
        [pscustomobject]@{
            Exists = $false
            Value  = $null
        }
    }

$TemporalValueState =
    if ($TemporalContextIsObject) {
        Get-ExplicitProperty -Object $TemporalContextState.Value -Name "Value"
    }
    else {
        [pscustomobject]@{
            Exists = $false
            Value  = $null
        }
    }

$TemporalSourceState =
    if ($TemporalContextIsObject) {
        Get-ExplicitProperty -Object $TemporalContextState.Value -Name "Source"
    }
    else {
        [pscustomobject]@{
            Exists = $false
            Value  = $null
        }
    }

$TemporalKind =
    if (
        $TemporalKindState.Exists -and
        $TemporalKindState.Value -is [string]
    ) {
        $TemporalKindState.Value.Trim()
    }
    else {
        $null
    }

$P07 =
    $null -ne $TemporalKind -and
    $AllowedTemporalKinds -contains $TemporalKind

$P08 =
    $TemporalValueState.Exists -and
    (Test-ExplicitScalar $TemporalValueState.Value)

$P09 =
    $TemporalSourceState.Exists -and
    (Test-ExplicitScalar $TemporalSourceState.Value)

$TemporalSourceNormalized =
    if (
        $P09 -and
        $TemporalSourceState.Value -is [string]
    ) {
        (
            $TemporalSourceState.Value.Trim().ToUpperInvariant() `
            -replace '[\s\-]+','_'
        )
    }
    else {
        $null
    }

$ProhibitedSourceUsed =
    $null -ne $TemporalSourceNormalized -and
    $ProhibitedTemporalSources -contains $TemporalSourceNormalized

$P10 =
    $P06 -and
    $P07 -and
    $P08 -and
    $P09 -and
    (-not $ProhibitedSourceUsed)

$PredicateObservations = @(
    (New-PredicateObservation `
        -Predicate "P01_CANDIDATE_ID_PRESENT" `
        -Satisfied $P01 `
        -Observed $CandidateIdState.Value `
        -Reason $(if ($P01) { "CandidateId directly observed." } else { "CandidateId absent or not explicit." })),

    (New-PredicateObservation `
        -Predicate "P02_CANDIDATE_PROVENANCE_PRESENT" `
        -Satisfied $P02 `
        -Observed $CandidateProvenanceState.Value `
        -Reason $(if ($P02) { "CandidateProvenance directly observed." } else { "CandidateProvenance absent or not explicit." })),

    (New-PredicateObservation `
        -Predicate "P03_GOVERNANCE_OBJECT_PRESENT" `
        -Satisfied $P03 `
        -Observed $GovernanceObjectState.Value `
        -Reason $(if ($P03) { "GovernanceObject directly observed." } else { "GovernanceObject absent or not explicit." })),

    (New-PredicateObservation `
        -Predicate "P04_OBJECT_IDENTITY_MATERIAL_PRESENT" `
        -Satisfied $P04 `
        -Observed $ObjectIdentityMaterialState.Value `
        -Reason $(if ($P04) { "ObjectIdentityMaterial directly observed." } else { "ObjectIdentityMaterial absent or not explicit." })),

    (New-PredicateObservation `
        -Predicate "P05_DECLARED_CONSEQUENTIAL_USE_PRESENT" `
        -Satisfied $P05 `
        -Observed $DeclaredConsequentialUseState.Value `
        -Reason $(if ($P05) { "DeclaredConsequentialUse directly observed." } else { "DeclaredConsequentialUse absent or not explicit." })),

    (New-PredicateObservation `
        -Predicate "P06_TEMPORAL_CONTEXT_PRESENT" `
        -Satisfied $P06 `
        -Observed $TemporalContextState.Value `
        -Reason $(if ($P06) { "TemporalContext object directly observed." } else { "TemporalContext absent or not an explicit object." })),

    (New-PredicateObservation `
        -Predicate "P07_TEMPORAL_CONTEXT_KIND_EXPLICIT_AND_ALLOWED" `
        -Satisfied $P07 `
        -Observed $TemporalKindState.Value `
        -Reason $(if ($P07) { "TemporalContext.Kind is explicit and allowed." } else { "TemporalContext.Kind absent, malformed or outside allowed set." })),

    (New-PredicateObservation `
        -Predicate "P08_TEMPORAL_CONTEXT_VALUE_PRESENT" `
        -Satisfied $P08 `
        -Observed $TemporalValueState.Value `
        -Reason $(if ($P08) { "TemporalContext.Value directly observed as an explicit scalar." } else { "TemporalContext.Value absent, empty or structurally ambiguous." })),

    (New-PredicateObservation `
        -Predicate "P09_TEMPORAL_CONTEXT_SOURCE_PRESENT" `
        -Satisfied $P09 `
        -Observed $TemporalSourceState.Value `
        -Reason $(if ($P09) { "TemporalContext.Source directly observed as an explicit scalar." } else { "TemporalContext.Source absent, empty or structurally ambiguous." })),

    (New-PredicateObservation `
        -Predicate "P10_NO_TEMPORAL_CONTEXT_INFERENCE_REQUIRED" `
        -Satisfied $P10 `
        -Observed $TemporalSourceState.Value `
        -Reason $(
            if ($P10) {
                "Required temporal context is directly present and no prohibited inference source is required."
            }
            elseif ($ProhibitedSourceUsed) {
                "TemporalContext.Source explicitly identifies a prohibited inference authority."
            }
            else {
                "Required temporal context is incomplete or ambiguous and would require inference to satisfy."
            }
        ))
)

$AbsentPredicates = @()
$AmbiguousPredicates = @()
$ContradictoryPredicates = @()

foreach ($Observation in $PredicateObservations) {

    if ($Observation.Satisfied) {
        continue
    }

    switch ($Observation.Predicate) {

        "P01_CANDIDATE_ID_PRESENT" {
            if (-not $CandidateIdState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P02_CANDIDATE_PROVENANCE_PRESENT" {
            if (-not $CandidateProvenanceState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P03_GOVERNANCE_OBJECT_PRESENT" {
            if (-not $GovernanceObjectState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P04_OBJECT_IDENTITY_MATERIAL_PRESENT" {
            if (-not $ObjectIdentityMaterialState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P05_DECLARED_CONSEQUENTIAL_USE_PRESENT" {
            if (-not $DeclaredConsequentialUseState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P06_TEMPORAL_CONTEXT_PRESENT" {
            if (-not $TemporalContextState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P07_TEMPORAL_CONTEXT_KIND_EXPLICIT_AND_ALLOWED" {
            if (-not $TemporalKindState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P08_TEMPORAL_CONTEXT_VALUE_PRESENT" {
            if (-not $TemporalValueState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P09_TEMPORAL_CONTEXT_SOURCE_PRESENT" {
            if (-not $TemporalSourceState.Exists) {
                $AbsentPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }

        "P10_NO_TEMPORAL_CONTEXT_INFERENCE_REQUIRED" {
            if ($ProhibitedSourceUsed) {
                $ContradictoryPredicates += $Observation.Predicate
            }
            else {
                $AmbiguousPredicates += $Observation.Predicate
            }
        }
    }
}

$AllSatisfied =
    @(
        $PredicateObservations |
        Where-Object {
            -not $_.Satisfied
        }
    ).Count -eq 0

$Determination =
    if ($AllSatisfied) {
        "ESTABLISHED"
    }
    else {
        "NOT_ESTABLISHED"
    }

$InspectionRecord =
    [pscustomobject][ordered]@{
        ReadOnlyInspection               = $true
        CandidateExists                  = $true
        JsonParseSucceeded               = $true
        CandidateContentAuthorityOnly    = $true
        TemporalContextDirectlyObserved  = $P06
        FilenameSemanticAuthorityUsed    = $false
        FilesystemMetadataAuthorityUsed  = $false
        SystemClockAuthorityUsed         = $false
        ExternalLookupAuthorityUsed      = $false
        InferenceSourcesUsed             = @()
        AllowedTemporalKinds             = @($AllowedTemporalKinds)
        ProhibitedTemporalSources        = @($ProhibitedTemporalSources)
        DesignSHA256                     = $DesignSHA256
        ConstructionGovernanceSHA256     = $ConstructionGovernanceSHA256
        Finding                          = $(
            if ($AllSatisfied) {
                "All required predicates directly established from designated candidate content."
            }
            else {
                "One or more required predicates are absent, ambiguous, contradictory or require prohibited inference."
            }
        )
    }

Write-BoundedResult `
    -ResolvedCandidatePath $ResolvedCandidatePath `
    -CandidateSHA256 $CandidateSHA256 `
    -CandidateId $CandidateIdState.Value `
    -CandidateProvenance $CandidateProvenanceState.Value `
    -PredicateObservations $PredicateObservations `
    -AbsentPredicates $AbsentPredicates `
    -AmbiguousPredicates $AmbiguousPredicates `
    -ContradictoryPredicates $ContradictoryPredicates `
    -Determination $Determination `
    -InspectionRecord $InspectionRecord