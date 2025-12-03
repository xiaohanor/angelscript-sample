class USanctuaryDoppelgangerMimicMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"MimicMovement");
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIAnimationComponent AnimComp;
	USteppingMovementData Movement;
	USanctuaryDoppelgangerComponent DoppelComp;

    FVector CustomVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		DoppelComp  = USanctuaryDoppelgangerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DoppelComp.MimicTarget == nullptr)
			return false;
		if (DoppelComp.MimicState != EDoppelgangerMimicState::FullMimic)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DoppelComp.MimicTarget == nullptr)
			return true;
		if (DoppelComp.MimicState != EDoppelgangerMimicState::FullMimic)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.SetActorEnableCollision(false);		
		Owner.BlockCapabilitiesExcluding(CapabilityTags::Movement, n"MimicMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.SetActorEnableCollision(true);		
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		// Note that we want to copy the local player instance, not crumb-replicate our control side.
		FVector Delta = DoppelComp.DoppelTransform.Location - Owner.ActorLocation;
		Movement.AddDelta(Delta);	
		Movement.SetRotation(DoppelComp.DoppelTransform.Rotation);		
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
	}
}
