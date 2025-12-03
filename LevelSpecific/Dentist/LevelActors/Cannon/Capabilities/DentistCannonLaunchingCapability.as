struct FDentistCannonLaunchingActivateParams
{
	FTraversalTrajectory LaunchTrajectory;
};

class UDentistCannonLaunchingCapability : UHazeCapability
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
	bool ShouldActivate(FDentistCannonLaunchingActivateParams& Params) const
	{
		if(!Cannon.IsOccupied())
			return false;

		if(!Cannon.IsStateActive(EDentistCannonState::Launching))
			return false;

		Params.LaunchTrajectory = Cannon.GetLaunchTrajectory();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Cannon.ResetDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistCannonLaunchingActivateParams Params)
	{
		AHazePlayerCharacter LaunchedPlayer = Cannon.GetPlayerInCannon();
		UDentistToothCannonComponent CannonComp = UDentistToothCannonComponent::Get(LaunchedPlayer);

		CannonComp.Launch(Params.LaunchTrajectory);

		UDentistCannonEventHandler::Trigger_OnLaunchPlayer(Cannon);

		Cannon.OnPlayerLaunched();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Cannon.StartResetting();
	}
};