struct FDoppelgangerMimicBehaviourParams
{
	AHazePlayerCharacter MimicTarget;
}

class USanctuaryDoppelgangerMimicBehaviour : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default DebugCategory = BasicAITags::Behaviour;

	FBasicBehaviourRequirements Requirements;
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	FBasicBehaviourCooldown Cooldown;

	UBasicBehaviourComponent BehaviourComp;
	UBasicAIAnimationComponent AnimComp;
	USanctuaryDoppelgangerComponent DoppelComp;
	UHazeCharacterSkeletalMeshComponent MeshComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BehaviourComp = UBasicBehaviourComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		BehaviourComp.RegisterBehaviour();
		Requirements.Priority = 1000 - BehaviourComp.NumRegisteredBehaviours;		
		MeshComp = Cast<AHazeCharacter>(Owner).Mesh;
		DoppelComp  = USanctuaryDoppelgangerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDoppelgangerMimicBehaviourParams& Params) const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (DoppelComp.MimicState != EDoppelgangerMimicState::FullMimic)
			return false;
		if (DoppelComp.MimicTarget == nullptr)
			return false;
		Params.MimicTarget = DoppelComp.MimicTarget;		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Note that we deactivate whenever cooldown is set, not when !Cooldown.IsOver
		if (Cooldown.IsSet())
			return true; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return true;
		if (DoppelComp.MimicState != EDoppelgangerMimicState::FullMimic)
			return true;
		if (DoppelComp.MimicTarget == nullptr)
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDoppelgangerMimicBehaviourParams Params)
	{
		Requirements.Claim(BehaviourComp, this);
		Cooldown.Reset();
		
		DoppelComp.MimicTarget = Params.MimicTarget;
		
		MeshComp.SetSkeletalMeshAsset(DoppelComp.MimicTarget.Mesh.SkeletalMeshAsset);
		TArray<UMaterialInterface> MimicMaterials = DoppelComp.MimicTarget.Mesh.Materials;
		for (int i = 0; i < MimicMaterials.Num(); i++)
		{
			MeshComp.SetMaterial(i, MimicMaterials[i]);
		}

		// Mimic feature will copy pose from mimic target
		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::DoppelgangerMimic, EBasicBehaviourPriority::Medium, this);	

		// Set up own features for mimicking this player's animations when we want to mimic appearance but not exact movement
		auto MovementFeature = Cast<ULocomotionFeatureSanctuaryDoppelgangerMovement>(MeshComp.GetFeatureByTag(LocomotionFeatureAISanctuaryTags::DoppelgangerMimicMovement));
		MovementFeature.MimicFeature(DoppelComp.MimicTarget);
		auto JumpFeature = Cast<ULocomotionFeatureSanctuaryDoppelgangerJump>(MeshComp.GetFeatureByTag(LocomotionFeatureAISanctuaryTags::DoppelgangerMimicJump));
		JumpFeature.MimicFeature(DoppelComp.MimicTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Requirements.Release(BehaviourComp, this);
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Doppelganger will move identical to target (with a one tick delay)
		// We can introduce positional glitches (or further delay here)
		DoppelComp.DoppelTransform = (DoppelComp.MimicTarget.ActorTransform * DoppelComp.MimicTargetInverseTransform) * DoppelComp.MimicTransform;
	}
}
