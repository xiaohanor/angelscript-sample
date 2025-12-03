class USanctuaryWeeperFireTrapCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;


	ASanctuaryWeeperFireTrap FireTrap;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FireTrap = Cast<ASanctuaryWeeperFireTrap>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FireTrap.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FireTrap.bIsActive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FireTrap.FireNiagara.Activate();

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FireTrap.FireNiagara.Deactivate();

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseBoxShape(FireTrap.Collision);
		TraceSettings.IgnoreActor(FireTrap);
		auto LightBirdUserComp = USanctuaryWeeperLightBirdUserComponent::Get(Game::Mio);
		TraceSettings.IgnoreActor(LightBirdUserComp.LightBird);


		FHitResult Hit = TraceSettings.QueryTraceSingle(FireTrap.ActorLocation, FireTrap.ActorLocation + FireTrap.ActorForwardVector * 2000);


		FireTrap.FireNiagara.SetWorldScale3D(FVector(1, 1, 1));


		if(Hit.bBlockingHit)
		{

			if(Hit.Actor == Game::Zoe)
			{
				Game::Zoe.KillPlayer();
				return;
			}
			
			auto Weeper = Cast<AAISanctuaryWeeper2D>(Hit.Actor);

			if(Weeper != nullptr)
			{
				Weeper.HealthComp.TakeDamage(Weeper.HealthComp.MaxHealth, EDamageType::Fire, Owner);
				return;
			}

			float Distance = (Hit.ImpactPoint - FireTrap.ActorLocation).Size();
			float Scale = (Distance - 200) * 0.0005;
			FireTrap.FireNiagara.SetWorldScale3D(FVector(Scale, 1, 1));

		}
	


	}
};