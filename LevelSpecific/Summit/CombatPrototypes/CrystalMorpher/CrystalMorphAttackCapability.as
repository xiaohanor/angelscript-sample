class UCrystalMorphAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CrystalMorphAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenGemCaster GemCaster;

	FVector AttackDirection;

	int CurrentInterval = 0;

	float ActivateTime;
	float DistanceInterval = 400.0;
	float CurrentDistance;

	float SpawnInterval = 0.05;
	float SpawnTime;

	bool bFinishedAttack;
	bool bTargetMio;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GemCaster = Cast<ANightQueenGemCaster>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!GemCaster.bUseMetalAttack)
			return false;

		if (!GemCaster.bIsActive)
			return false;

		if (Time::GameTimeSeconds < ActivateTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!GemCaster.bUseMetalAttack)
			return true;
		
		if (bFinishedAttack)
			return true;
		
		if (!GemCaster.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bFinishedAttack = false;
		bTargetMio = !bTargetMio;

		if (bTargetMio)
			AttackDirection = (Game::Mio.ActorLocation - GemCaster.ActorLocation).GetSafeNormal();
		else
			AttackDirection = (Game::Zoe.ActorLocation - GemCaster.ActorLocation).GetSafeNormal();

		CurrentDistance = 0.0;
		CurrentInterval = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActivateTime = Time::GameTimeSeconds + GemCaster.ActivateDuration;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + SpawnInterval;
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
			TraceSettings.IgnoreActor(GemCaster);
			TraceSettings.IgnoreActor(Game::Mio);
			TraceSettings.IgnoreActor(Game::Zoe);
			TraceSettings.UseLine();

			FVector TraceLocation = GemCaster.ActorLocation + AttackDirection * CurrentDistance;
			TraceLocation += FVector(0.0, 0.0, 200.0);

			FHitResult Hit = TraceSettings.QueryTraceSingle(TraceLocation, TraceLocation + -FVector::UpVector * 1500.0);

			if (Hit.bBlockingHit)
			{
				GemCaster.SpawnMetalMorpher(Hit.ImpactPoint);
			}

			CurrentInterval++;

			CurrentDistance += DistanceInterval;

			if (CurrentInterval > GemCaster.SpawnAmount)
				bFinishedAttack = true;
		}
	}
}