class USkylineBossSeekerMissileAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossSeekerMissileAttack);

	TArray<USkylineBossProjectileLauncherComponent> ProjectileLaunchers;
	TArray<AActor> ActorsToIgnore;
	
	int LaunchIndex = 0;
	float NextLaunchTime = 0.0;
	
	const float LaunchInterval = 0.3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Boss.GetComponentsByClass(ProjectileLaunchers);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 3.0)
			return false;

		if (Boss.LookAtTarget.Get() == nullptr)
			return false;

		if (Owner.GetDistanceTo(Boss.LookAtTarget.Get()) < Boss.Settings.MinLongRangeAttacks)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (LaunchIndex >= ProjectileLaunchers.Num())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LaunchIndex = 0;
		NextLaunchTime = Time::GameTimeSeconds;

		auto Target = Boss.LookAtTarget.Get();

		PrintToScreen("Fire Missiles at: " + Target, 3.0, FLinearColor::Green);

		ActorsToIgnore.Reset();

		for (auto ProjectileLauncher : ProjectileLaunchers)
			ActorsToIgnore.Add(ProjectileLauncher.PrepareProjectileLaunch(Target));
	
//		for (auto ProjectileLauncher : ProjectileLaunchers)
//			ProjectileLauncher.LaunchPreparedProjectile(ActorsToIgnore);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		while (Time::GameTimeSeconds >= NextLaunchTime)
		{
			ProjectileLaunchers[LaunchIndex].LaunchPreparedProjectile(ActorsToIgnore);
			NextLaunchTime += LaunchInterval;
			LaunchIndex++;
		}
	}
}