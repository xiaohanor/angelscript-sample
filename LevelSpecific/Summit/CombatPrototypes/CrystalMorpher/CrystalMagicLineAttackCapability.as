class UCrystalMagicLineAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CrystalMagicLineAttackCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ANightQueenGemCaster GemCaster;

	FHazeAcceleratedVector AccelAttackDir;

	int CurrentInterval = 0;

	float ActivateTime;
	float DistanceInterval = 170.0;
	float CurrentDistance;

	float SpawnInterval = 0.015;
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
		if (GemCaster.bUseMetalAttack)
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
		if (GemCaster.bUseMetalAttack)
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

		AccelAttackDir.SnapTo((Game::Mio.ActorLocation - GemCaster.ActorLocation).GetSafeNormal());
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
		if (bTargetMio)
			AccelAttackDir.AccelerateTo((Game::Mio.ActorLocation - GemCaster.ActorLocation).GetSafeNormal(), 0.25, DeltaTime);
		else
			AccelAttackDir.AccelerateTo((Game::Zoe.ActorLocation - GemCaster.ActorLocation).GetSafeNormal(), 0.25, DeltaTime);

		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + SpawnInterval;
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
			TraceSettings.IgnoreActor(GemCaster);
			TraceSettings.UseLine();

			FVector SpawnLocation = GemCaster.ActorLocation + AccelAttackDir.Value.GetSafeNormal() * CurrentDistance;
			SpawnLocation += FVector(0.0, 0.0, 2000.0);

			FVector RightAxis = AccelAttackDir.Value.CrossProduct(FVector::UpVector);
			SpawnLocation += RightAxis * Math::RandRange(-400.0, 400.0);

			GemCaster.SpawnMagicSpear(SpawnLocation);

			CurrentInterval++;

			CurrentDistance += DistanceInterval;

			if (CurrentInterval > GemCaster.SpawnAmount * 6)
				bFinishedAttack = true;
		}
	}	
}