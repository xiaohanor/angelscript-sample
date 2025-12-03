class USkylineBossRocketBarrageLaunchingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineBoss Boss;
	USkylineBossRocketBarrageComponent RocketBarrageComp;

	int LaunchIndex = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBoss>(Owner);
		RocketBarrageComp = USkylineBossRocketBarrageComponent::Get(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RocketBarrageComp.IsLaunchingRockets())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RocketBarrageComp.IsLaunchingRockets())
			return true;

		if(LaunchIndex >= RocketBarrageComp.NumOfRockets)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LaunchIndex = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(RocketBarrageComp.IsLaunchingRockets())
			RocketBarrageComp.StopLaunching();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		int TargetLaunchIndex = Math::Min(Math::FloorToInt(ActiveDuration / RocketBarrageComp.LaunchInterval), RocketBarrageComp.NumOfRockets);
		while(LaunchIndex < TargetLaunchIndex)
		{
			auto RocketBarrageTarget = RocketBarrageComp.GetRocketBarrageTarget(RocketBarrageComp.TargetActor.ActorLocation + (RocketBarrageComp.TargetActor.ActorHorizontalVelocity * 1.5));
			RocketBarrageComp.LaunchRocket(RocketBarrageTarget, LaunchIndex);
			LaunchIndex++;
		}
	}
};