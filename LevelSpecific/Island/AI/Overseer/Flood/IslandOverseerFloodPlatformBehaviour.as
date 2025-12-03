class UIslandOverseerFloodPlatformBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerFloodAttackComponent FloodAttackComp;
	FBasicAIAnimationActionDurations Durations;
	AAIIslandOverseer Overseer;
	UIslandOverseerFloodComponent FloodComp;

	TArray<AIslandOverseerFloodShootablePlatform> CurrentPlatforms;
	float Duration = 1.77;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		FloodAttackComp = UIslandOverseerFloodAttackComponent::Get(Owner);
		FloodComp = UIslandOverseerFloodComponent::Get(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())	
			return;
		if(!FloodAttackComp.bFloodRunning)
			return;

		for(AIslandOverseerFloodShootablePlatform Platform : FloodComp.Platforms)
		{
			if(!CanClosePlatform(Platform, 1400))
				continue;

			for(AIslandOverseerFloodShootablePlatform NearbyPlatform : FloodComp.Platforms)
			{
				if(!CanClosePlatform(NearbyPlatform, 1900))
					continue;
				CurrentPlatforms.Add(NearbyPlatform);
			}
		}
	}

	bool CanClosePlatform(AIslandOverseerFloodShootablePlatform Platform, float Distance)
	{
		if(Platform.bClosed)
			return false;
		if(Owner.ActorUpVector.DotProduct(Platform.ActorLocation - Owner.ActorLocation) < 0)
			return false;
		if(Platform.GetVerticalDistanceTo(Owner) > Distance)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!FloodAttackComp.bFloodRunning)
			return false;
		if(CurrentPlatforms.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AnimComp.RequestSubFeature(SubTagIslandOverseerFlood::Platform, Owner, Duration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(0.1);
		AnimComp.RequestSubFeature(SubTagIslandOverseerFlood::Idle, Owner);
		CurrentPlatforms.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < Duration / 2)
			return;

		for(AIslandOverseerFloodShootablePlatform Platform : CurrentPlatforms)
		{
			if(!Platform.bClosed)
			{
				Platform.Close();
				UIslandOverseerEventHandler::Trigger_OnFloodPlatformPull(Owner);
			}
		}
	}
}