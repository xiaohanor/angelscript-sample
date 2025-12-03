class ASanctuaryWeeperFireTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperFireTrapCapability");

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FireNiagara;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;

	float Angle;
	bool bIsActive = true;



	void ActivateFire()
	{
		bIsActive = true;
	}

	void DeactivateFire()
	{
		bIsActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		// TraceSettings.UseBoxShape(Collision);
		// TraceSettings.IgnoreActor(this);

		// FHitResultArray HitResultArray = TraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + ActorForwardVector);

		// for(FHitResult Hit : HitResultArray)
		// {
		// 	if(Hit.bBlockingHit)
		// 	{

		// 		if(Hit.Actor == Game::Zoe)
		// 		{
		// 			Game::Zoe.KillPlayer();
		// 			return;
		// 		}
				
		// 		auto Weeper = Cast<AAISanctuaryWeeper2D>(Hit.Actor);

		// 		if(Weeper != nullptr)
		// 			Weeper.HealthComp.TakeDamage(Weeper.HealthComp.MaxHealth, EDamageType::Explosion, this);

				
		// 	}
		// }
	}
	

};