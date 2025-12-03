class USkylineBossVulcanoAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);

	USkylineBossVulcanoComponent VulcanoComp;

	int LaunchIndex = 0;
	float LaunchTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		VulcanoComp = USkylineBossVulcanoComponent::Get(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
/*
//		if (Boss.GetPhase() != ESkylineBossPhase::Second)
//			return false;

		if (!Boss.IsStateActive(ESkylineBossState::Down))
			return false;

		if (DeactiveDuration < 3.0)
			return false;

		return true;
*/
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 3.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("Vulcano Attack", 1.0, FLinearColor::Red);

//		VulcanoComp.Fire();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > LaunchTime)
		{
			auto MioVulcanoTarget = VulcanoComp.GetVulcanoTarget(Boss.GetBikeFromTarget(Game::Mio).ActorLocation + (Boss.GetBikeFromTarget(Game::Mio).ActorHorizontalVelocity * 1.5));
			VulcanoComp.Fire(Boss.GetBikeFromTarget(Game::Mio), VulcanoComp.WorldLocation, MioVulcanoTarget.Location);
			auto ZoeVulcanoTarget = VulcanoComp.GetVulcanoTarget(Boss.GetBikeFromTarget(Game::Mio).ActorLocation + (Boss.GetBikeFromTarget(Game::Zoe).ActorHorizontalVelocity * 1.5));
			VulcanoComp.Fire(Boss.GetBikeFromTarget(Game::Zoe), VulcanoComp.WorldLocation, ZoeVulcanoTarget.Location);

///			RocketBarrageComp.LaunchRocket(Targets[LaunchIndex]);
			LaunchTime = Time::GameTimeSeconds + VulcanoComp.LaunchInterval;
			LaunchIndex++;
		}
	}
}