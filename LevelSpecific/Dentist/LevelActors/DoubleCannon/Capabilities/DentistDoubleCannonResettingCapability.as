class UDentistDoubleCannonResettingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistDoubleCannon Cannon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ADentistDoubleCannon>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Cannon.IsStateActive(EDentistDoubleCannonState::Resetting))
			return false;

		// Wait a lil while
		if(Time::GetGameTimeSince(Cannon.ResetStartTime) < 2)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cannon.IsStateActive(EDentistDoubleCannonState::Resetting))
			return true;

		if(ActiveDuration > Cannon.ResetDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UDentistDoubleCannonEventHandler::Trigger_OnStartResetting(Cannon);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UDentistDoubleCannonEventHandler::Trigger_OnFinishedResetting(Cannon);
		
		Cannon.SetCannonAlpha(0);
		Cannon.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / Cannon.ResetDuration);
		Cannon.SetCannonAlpha(1.0 - Alpha);
	}
};