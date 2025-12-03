class ANightQueenGemConjurer : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"NightQueenConjurerAttackCapability");
	
	UPROPERTY()
	TSubclassOf<ANightQueenConjurerGemSword> GemSwordClass;
	
	UPROPERTY(EditAnywhere)
	float DistanceActivation = 4000.0;

	bool bSendToMio;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) override
	{
		Super::Tick(DeltaSeconds);
		AddActorLocalRotation(FRotator(0.0, 30.0 * DeltaSeconds, 0.0));
	}

	void SpawnSword()
	{
		float Ry = Math::RandRange(-600.0, 600.0);
		FVector GoToLocation = ActorLocation + FVector(0.0, 0.0, 700.0);
		GoToLocation += ActorRightVector * Ry;
		ANightQueenConjurerGemSword Sword = SpawnActor(GemSwordClass, ActorLocation, (GoToLocation - ActorLocation).Rotation(), NAME_None, true);
		Sword.StartLocation = GoToLocation;
		Sword.TargetPlayer = bSendToMio ? Game::Mio : Game::Zoe;
		bSendToMio = !bSendToMio;
		FinishSpawningActor(Sword);
	}
}