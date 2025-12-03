class UArenaBossBombCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::Bombs;

	default ChargeUpDuration = 1.2;
	default WindDownDuration = 1.5;

	float BombDelay = 0.3;
	float CurrentBombTimer = 0.0;

	int MaxBombAmount = 36;
	int CurrentBombAmount = 0;

	int MaxSocketIndex = 7;
	int CurrentSocketIndex = 0;

	bool bFirstBombLaunched = false;

	int DirectTargetInterval = 3;
	int CurrentDirectTarget = 0;

	TArray<FName> SocketNames;
	default SocketNames.Add(n"RightFrontLowerMissileSocket");
	default SocketNames.Add(n"LeftFrontLowerMissileSocket");
	default SocketNames.Add(n"RightBackLowerMissileSocket");
	default SocketNames.Add(n"LeftBackLowerMissileSocket");
	default SocketNames.Add(n"RightFrontUpperMissileSocket");
	default SocketNames.Add(n"LeftFrontUpperMissileSocket");
	default SocketNames.Add(n"RightBackUpperMissileSocket");
	default SocketNames.Add(n"LeftBackUpperMissileSocket");

	AHazePlayerCharacter CurrentTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		CurrentTarget = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bFirstBombLaunched = false;

		CurrentBombTimer = 0.0;
		CurrentBombAmount = 0;
		CurrentSocketIndex = 0;

		UArenaBossEffectEventHandler::Trigger_BombStateEntered(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.StopAllInstancesOfCameraShake(Boss.BombPassiveCameraShake);

		UArenaBossEffectEventHandler::Trigger_BombStateEnded(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FVector TargetLoc = bWindingDown ? Boss.DefaultLocation : Boss.DefaultLocation - (FVector::UpVector * 400.0);
		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLoc, DeltaTime, 250.0);
		Boss.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, Boss.DefaultRotation, 0.8, DeltaTime);
		Boss.SetActorRotation(Rot);

		if (IsChargingUpOrWindingDown())
			return;

		if (ActiveDuration >= ChargeUpDuration + 0.1)
			Boss.AnimationData.bLaunchingBombs = true;

		CurrentBombTimer += DeltaTime;
		if (CurrentBombTimer >= BombDelay)
		{
			LaunchBomb();
		}
	}

	void LaunchBomb()
	{
		CurrentBombTimer = 0.0;

		CurrentTarget = CurrentTarget.IsMio() ? Game::Zoe : Game::Mio;

		FName SpawnSocket = SocketNames[CurrentSocketIndex];

		FVector SpawnLoc = Boss.Mesh.GetSocketLocation(SpawnSocket);
		FRotator SpawnRot = Boss.Mesh.GetSocketRotation(SpawnSocket);
		FVector SpawnDir = SpawnRot.UpVector;

		AArenaBomb Bomb = SpawnActor(Boss.BombClass, SpawnLoc, SpawnDir.Rotation());

		bool bDirectHit = false;
		if (CurrentDirectTarget >= DirectTargetInterval - 1)
		{
			CurrentDirectTarget = 0;
			bDirectHit = true;
		}
		else
			CurrentDirectTarget++;

		Bomb.LaunchBomb(Boss, CurrentTarget, bDirectHit);

		UArenaBossEffectEventHandler::Trigger_BombLaunched(Boss);

		CurrentBombAmount++;
		if (CurrentBombAmount >= MaxBombAmount)
			StartWindingDown();

		CurrentSocketIndex++;
		if (CurrentSocketIndex > MaxSocketIndex)
			CurrentSocketIndex = 0;
	}

	void ChargedUp() override
	{
		Super::ChargedUp();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayCameraShake(Boss.BombPassiveCameraShake, this);
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();
		UArenaBossEffectEventHandler::Trigger_BombStateWindDown(Boss);

		Boss.AnimationData.bLaunchingBombs = false;
	}
}