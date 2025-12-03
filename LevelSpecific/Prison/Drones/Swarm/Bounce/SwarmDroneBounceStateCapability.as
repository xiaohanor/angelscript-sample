class USwarmDroneBounceStateCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	USwarmDroneBounceComponent BouncedComp;
	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerMovementComponent MoveComp;

	bool bHadImpactLastFrame = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BouncedComp = USwarmDroneBounceComponent::Get(Player);
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);
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

		if(SwarmDroneComponent.bJumping)
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
		Player.BlockCapabilities(SwarmDroneTags::BlockedWhileInSwarmDroneBounce, this);
		USwarmDroneEventHandler::Trigger_OnBounce(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BouncedComp.bIsInBounceState = false;
		Player.UnblockCapabilities(SwarmDroneTags::BlockedWhileInSwarmDroneBounce, this);
		USwarmDroneEventHandler::Trigger_OnBounce(Player);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("bIsInBounceState", BouncedComp.bIsInBounceState);
	}
#endif
};