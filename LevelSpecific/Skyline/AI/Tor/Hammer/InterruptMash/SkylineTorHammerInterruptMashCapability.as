class USkylineTorHammerInterruptMashCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	USkylineTorHammerComponent HammerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HammerComp.bInterruptGrabMash)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 0.25)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HammerComp.bInterruptGrabMash = false;
		USkylineTorHammerEventHandler::Trigger_OnInterruptGrabMashStart(Owner, FOnInterruptGrabMashData(Game::Zoe));
		FStumble Stumble;
		FVector Dir = (Game::Zoe.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Game::Zoe.ActorForwardVector);
		Stumble.Move = Dir * 500;
		Stumble.Duration = 0.5;
		Game::Zoe.ApplyStumble(Stumble);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		USkylineTorHammerEventHandler::Trigger_OnInterruptGrabMashStop(Owner, FOnInterruptGrabMashData(Game::Zoe));
	}
}