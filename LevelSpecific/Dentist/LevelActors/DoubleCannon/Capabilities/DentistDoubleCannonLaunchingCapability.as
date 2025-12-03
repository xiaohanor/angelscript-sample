struct FDentistDoubleCannonLaunchingActivateParams
{
	FTraversalTrajectory LaunchTrajectory;
};

class UDentistDoubleCannonLaunchingCapability : UHazeCapability
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
	bool ShouldActivate(FDentistDoubleCannonLaunchingActivateParams& Params) const
	{
		if(!Cannon.IsStateActive(EDentistDoubleCannonState::Launching))
			return false;

		Params.LaunchTrajectory = Cannon.LaunchTrajectory;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cannon.IsStateActive(EDentistDoubleCannonState::Aiming))
			return true;

		if(Cannon.GetPredictedTimeSinceLaunchStart() > Cannon.GetDetachTime() + Cannon.ResetDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistDoubleCannonLaunchingActivateParams Params)
	{
		// Sync the launch trajectory to Remote
		Cannon.LaunchTrajectory = Params.LaunchTrajectory;

		for(auto LaunchedPlayer : Game::Players)
		{
			auto CannonComp = UDentistToothDoubleCannonComponent::Get(LaunchedPlayer);
			CannonComp.Launch();
		}

		Cannon.SpringTranslateComp.ApplyImpulse(Cannon.SpringTranslateComp.WorldLocation, Cannon.SpringTranslateComp.UpVector * -500);

		Cannon.OnPlayersLaunched.Broadcast();
		UDentistDoubleCannonEventHandler::Trigger_OnLaunchPlayers(Cannon);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Cannon.StartResetting();
	}
};