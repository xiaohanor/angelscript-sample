class UMagnetDroneBounceStateCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UMagnetDroneBounceComponent BouncedComp;
	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneAttachToBoatComponent AttachToBoatComp;
	UPlayerMovementComponent MoveComp;

	bool bHadImpactLastFrame = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BouncedComp = UMagnetDroneBounceComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		AttachToBoatComp = UMagnetDroneAttachToBoatComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		bHadImpactLastFrame = MoveComp.HasAnyValidBlockingImpacts();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BouncedComp.HasResolverBouncedThisFrame())
			return false;

		if(!MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.IsInAir())
			return true;

		if(AttachToBoatComp.bHasLandedOnBoat)
			return true;

		if(JumpComp.IsJumping())
			return true;

		return false;
	}

	// UFUNCTION(BlueprintOverride)
	// void PreTick(float DeltaTime)
	// {
	// 	if(MoveComp.HasImpactedGround() && !bHadImpactLastFrame)
	// 		UMagnetDroneEventHandler::Trigger_MagnetDroneBounce(Player);

	// 	bHadImpactLastFrame = MoveComp.HasImpactedGround();
	// }

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BouncedComp.bIsInBounceState = true;
		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileInMagnetDroneBounce, this);
		UMagnetDroneEventHandler::Trigger_MagnetDroneBounce(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BouncedComp.bIsInBounceState = false;
		Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileInMagnetDroneBounce, this);
		UMagnetDroneEventHandler::Trigger_MagnetDroneBounce(Player);
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("bIsInBounceState", BouncedComp.bIsInBounceState);
	}
	#endif
};