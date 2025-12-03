class UDentistDoubleCannonMoveLaunchedRootCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ADentistDoubleCannon Cannon;
	TPerPlayer<UDentistToothDoubleCannonComponent> CannonComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cannon = Cast<ADentistDoubleCannon>(Owner);
		Cannon.LaunchedRoot.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Cannon.IsStateActive(EDentistDoubleCannonState::Launching))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Cannon.GetPredictedTimeSinceLaunchStart() > Cannon.GetLaunchTrajectory().GetTotalTime())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Reset LaunchedRoot to the start
		Cannon.LaunchedRoot.RemoveActorDisable(this);
		Cannon.LaunchedRoot.SetActorTransform(GetCurrentLaunchedRootTransform());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Cannon.LaunchedRoot.SetActorTransform(GetInitialLaunchedRootTransform());
		Cannon.LaunchedRoot.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Cannon.LaunchedRoot.SetActorTransform(GetCurrentLaunchedRootTransform());
	}

	FTransform GetInitialLaunchedRootTransform() const
	{
		const FTraversalTrajectory Trajectory = Cannon.GetLaunchTrajectory();

		return Cannon.GetLaunchedRootTransformAtTime(
			Trajectory,
			0
		);
	}

	FTransform GetCurrentLaunchedRootTransform() const
	{
		const FTraversalTrajectory Trajectory = Cannon.GetLaunchTrajectory();
		const float LaunchTime = Cannon.GetPredictedTimeSinceLaunchStart();

		return Cannon.GetLaunchedRootTransformAtTime(
			Trajectory,
			LaunchTime
		);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		const float LaunchTime = Cannon.GetPredictedTimeSinceLaunchStart();

		TemporalLog.Transform("Launched Root", Cannon.LaunchedRoot.ActorTransform, 500);
		TemporalLog.Value("Launch Time", LaunchTime);
		TemporalLog.Value("Total Launch Time", Cannon.GetLaunchTrajectory().GetTotalTime());
	}
#endif
};