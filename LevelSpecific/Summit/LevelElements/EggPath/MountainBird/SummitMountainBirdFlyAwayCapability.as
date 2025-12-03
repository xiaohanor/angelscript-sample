class USummitMountainFlyAwayCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AAISummitMountainBird MountainBird;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		MountainBird = Cast<AAISummitMountainBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::TakeFlight)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MountainBird.CurrentState != ESummitMountainBirdFlightState::TakeFlight)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MountainBird.SetCurrentState(ESummitMountainBirdFlightState::TakeFlight);
		if (MountainBird.CurrentLandingSpot != nullptr)
			MountainBird.CurrentLandingSpot.Release();

		SummitMountainBird::Animations::PlayFlyAwayAnimation(MountainBird);
		USummitMountainBirdEventHandler::Trigger_OnTakeOff(Owner);
	}


	
};