
class UIslandDyadLaserBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandDyadSettings DyadSettings;
	UIslandDyadLaserComponent LaserComp;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	FVector EndLocation;
	FVector LocalEndLocation;
	AAIIslandDyad Dyad;
	float DamageTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DyadSettings = UIslandDyadSettings::GetSettings(Owner);
		LaserComp = UIslandDyadLaserComponent::Get(Owner);
		Dyad = Cast<AAIIslandDyad>(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(LaserComp.OtherDyad == nullptr)
			return false;
		if(!LaserComp.bPrimaryDyad)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(LaserComp.OtherDyad == nullptr)
			return true;
		if(!LaserComp.bPrimaryDyad)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, DyadSettings.LaserGentlemanCost);
		DamageTime = 0;

		UIslandDyadEffectHandler::Trigger_OnStartedLaser(Owner, FIslandDyadAimingEventData(LaserComp));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandDyadEffectHandler::Trigger_OnStoppedLaser(Owner);
		GentCostComp.ReleaseToken(this);
		Cooldown.Set(2);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Dyad.OtherDyad == nullptr)
			return;
		
		LaserComp.AimingLocation.StartLocation = Dyad.ActorCenterLocation;
		LaserComp.AimingLocation.EndLocation = Dyad.OtherDyad.ActorCenterLocation;
		LaserTrace();
	}

	void LaserTrace()
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseLine();
		Trace.IgnoreActor(Dyad);
		Trace.IgnoreActor(Dyad.OtherDyad);
		FHitResult Hit = Trace.QueryTraceSingle(Dyad.ActorCenterLocation, Dyad.OtherDyad.ActorCenterLocation);

		if(Hit.bBlockingHit)
		{
			UIslandDyadEffectHandler::Trigger_OnLaserHit(Owner, FIslandDyadLaserHitEventData(Hit.Location));
			if(DamageTime == 0 || Time::GetGameTimeSince(DamageTime) > DyadSettings.LaserDamageInterval)
			{
				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if ((Player != nullptr) && Player.HasControl())
					DealDamage(Player);
				DamageTime = Time::GetGameTimeSeconds();
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void DealDamage(AHazePlayerCharacter PlayerTarget)
	{
		// Player damage is crumbed already
		PlayerTarget.DealBatchedDamageOverTime(DyadSettings.LaserPlayerDamagePerSecond * DyadSettings.LaserDamageInterval, FPlayerDeathDamageParams());
	}
}