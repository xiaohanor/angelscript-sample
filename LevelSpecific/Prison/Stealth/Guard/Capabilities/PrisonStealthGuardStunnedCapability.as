class UPrisonStealthGuardStunnedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthGuard);

	APrisonStealthGuard StealthGuard;
    UPrisonStealthVisionComponent VisionComp;
	UPrisonStealthStunnedComponent StunnedComp;
	UPrisonStealthDetectionComponent DetectionComp;

	FRotator StartRotation;
	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StealthGuard = Cast<APrisonStealthGuard>(Owner);
        VisionComp = UPrisonStealthVisionComponent::Get(Owner);
		StunnedComp = UPrisonStealthStunnedComponent::Get(Owner);
		DetectionComp = UPrisonStealthDetectionComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!StunnedComp.ShouldBeStunned())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!StunnedComp.ShouldBeStunned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StunnedComp.bIsStunned = true;

		FPrisonStealthGuardOnStunStartedParams Params;
		Params.bReset = false;
		UPrisonStealthGuardEventHandler::Trigger_OnStunStarted(StealthGuard, Params);
		
		for(auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			StealthGuard.SetDetectionAlpha(Player, 0, true);
		}
		
		StartRotation = StealthGuard.ActorRotation;	

		StealthGuard.BlockCapabilities(PrisonStealthTags::BlockedWhileStunned, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StunnedComp.bIsStunned = false;

		StealthGuard.UnblockCapabilities(PrisonStealthTags::BlockedWhileStunned, this);

		StunnedComp.ResetStun();
		UPrisonStealthGuardEventHandler::Trigger_OnStunStopped(StealthGuard);
		StealthGuard.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// This is to prevent the spring location from springing back when stunned, which looks weird
		StealthGuard.TargetLocation = FVector(StealthGuard.ActorLocation.X, StealthGuard.ActorLocation.Y, StealthGuard.TargetLocation.Z);
	}
}