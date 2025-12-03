struct FPinballBossBallPredictionDispatchedLaunch
{
	UPinballLauncherComponent LauncherComp;
	float DispatchTime;
};

class UPinballBossBallPredictionImpactsCapability : UPinballBossBallPredictionBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPinballProxyMovementComponent ProxyMoveComp;
	UPinballBallComponent BallComp;

	TArray<FPinballBossBallPredictionDispatchedLaunch> DispatchedLaunches;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(HasControl())
			return;

		Super::Setup();

		ProxyMoveComp = Proxy.MoveComp;
		BallComp = UPinballBallComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DispatchedLaunches.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ClearOldDispatches();

		for(const FPinballMagnetDroneProxyMovementIterationResult& IterationResult : ProxyMoveComp.IterationResults)
		{
			if(IterationResult.LaunchData.IsValid())
			{
				// We don't allow dispatching launches too close together, because the prediction can hit the same launcher for multiple frames
				if(CanDispatchLaunch(IterationResult.LaunchData))
					DispatchLaunch(IterationResult.LaunchData);
			}
		}
	}

	void ClearOldDispatches()
	{
		const float ResetTime = Time::GameTimeSeconds - (Network::PingRoundtripSeconds * 2);

		for(int i = DispatchedLaunches.Num() - 1; i >= 0; i--)
		{
			// Remove old launches that have expired
			if(DispatchedLaunches[i].DispatchTime < ResetTime)
				DispatchedLaunches.RemoveAtSwap(i);
		}
	}

	bool CanDispatchLaunch(FPinballBallLaunchData LaunchData) const
	{
		for(const FPinballBossBallPredictionDispatchedLaunch& DispatchedLaunch : DispatchedLaunches)
		{
			if(DispatchedLaunch.LauncherComp == LaunchData.LaunchedBy)
				return false;
		}

		return true;
	}

	void DispatchLaunch(FPinballBallLaunchData LaunchData)
	{
		if(!ensure(LaunchData.IsValid()))
			return;
		
		BallComp.Launch(LaunchData);

		FPinballBossBallPredictionDispatchedLaunch DispatchedLaunch;
		DispatchedLaunch.LauncherComp = LaunchData.LaunchedBy;
		DispatchedLaunch.DispatchTime = Time::GameTimeSeconds;
		DispatchedLaunches.Add(DispatchedLaunch);
	}
};