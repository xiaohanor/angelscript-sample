class UDentistCannonResettingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistCannon Cannon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ADentistCannon>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Cannon.IsStateActive(EDentistCannonState::Resetting))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cannon.IsStateActive(EDentistCannonState::Resetting))
			return true;

		if(ActiveDuration > Cannon.ResetDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UDentistCannonEventHandler::Trigger_OnStartResetting(Cannon);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UDentistCannonEventHandler::Trigger_OnFinishedResetting(Cannon);
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