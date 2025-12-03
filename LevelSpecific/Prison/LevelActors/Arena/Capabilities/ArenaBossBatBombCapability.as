class UArenaBossBatBombCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::BatBomb;
	default bResetToIdleOnDeactivation = false;

	default WindDownDuration = 1.5;

	bool bCharging = false;
	float ChargeDuration = 0.1;
	float CurrentChargeTime = 0.0;

	bool bBatting = false;
	float BatDuration = 1.9;
	float CurrentBatTime = 0.0;

	bool bBombsReleased = false;

	int MaxBombAmount = 6;
	int CurrentBombAmount = 0;

	TArray<AArenaBossBatBomb> Bombs;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bCharging = true;
		bBatting = false;

		CurrentChargeTime = 0.0;
		CurrentBatTime = 0.0;

		CurrentBombAmount = 0;

		SetCameraChaseEnabled(false);

		UArenaBossEffectEventHandler::Trigger_BatBombStateEntered(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Boss.ActivateState(EArenaBossState::ArmThrow);

		SetCameraChaseEnabled(true);

		UArenaBossEffectEventHandler::Trigger_BatBombStateEnded(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Debug::DrawDebugSphere(Boss.Mesh.GetSocketLocation(n"Align"), 200.0, 12, FLinearColor::DPink, 10.0);

		FVector Loc = Math::VInterpTo(Boss.ActorLocation, Boss.BatBombTargetPoint.ActorLocation, DeltaTime, 2.0);
		Boss.SetActorLocation(Loc);

		Super::TickActive(DeltaTime);

		if (IsChargingUpOrWindingDown())
			return;

		if (bCharging)
		{
			CurrentChargeTime += DeltaTime;
			if (CurrentChargeTime >= ChargeDuration)
				TriggerAttack();
		}

		if (bBatting)
		{
			CurrentBatTime += DeltaTime;
			if (CurrentBatTime >= BatDuration)
			{
				Boss.AnimationData.bBatting = false;

				if (CurrentBombAmount >= MaxBombAmount)
					StartWindingDown();
				else
					StartChargingAttack();
			}

			if (CurrentBatTime >= 0.75)
				ReleaseBombs();
		}
	}

	void StartChargingAttack()
	{
		bBatting = false;
		bCharging = true;
		CurrentChargeTime = 0.0;
	}

	void TriggerAttack()
	{
		Boss.AnimationData.bBatting = true;

		bCharging = false;
		bBombsReleased = false;
		CurrentBatTime = 0.0;
		bBatting = true;

		CurrentBombAmount++;

		Bombs.Empty();
		for (int i = 0; i <= 15; i++)
		{
			AArenaBossBatBomb Bomb = SpawnActor(Boss.BatBombClass, Boss.Mesh.GetSocketLocation(n"LeftBackUpperMissile"));
			Bomb.AttachToComponent(Boss.Mesh, n"Align", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);

			FVector Offset = FVector::ZeroVector;
			if (i == 1 || i == 9)
				Offset = FVector(0.0, 240.0, 0.0);
			if (i == 2 || i == 10)
				Offset = FVector(-300.0, 0.0, 0.0);
			if (i == 3 || i == 11)
				Offset = FVector(-300.0, 240.0, 0.0);
			if (i == 4 || i == 12)
				Offset = FVector(0.0, 0.0, -200.0);
			if (i == 5 || i == 13)
				Offset = FVector(0.0, 240.0, -200.0);
			if (i == 6 || i == 14)
				Offset = FVector(-300.0, 0.0, -200.0);
			if (i == 7 || i == 15)
				Offset = FVector(-300.0, 240.0, -200.0);

			Bomb.SetActorRelativeLocation(Offset);
			Bomb.SetActorRelativeRotation(FRotator(90.0, 0.0, 0.0));

			Bomb.LaunchedFromSocket();

			Bombs.Add(Bomb);
		}

		UArenaBossEffectEventHandler::Trigger_BatBombAttack(Boss);
	}

	void ReleaseBombs()
	{
		if (bBombsReleased)
			return;

		bBombsReleased = true;

		AHazePlayerCharacter TargetPlayer = Game::Mio;
		int BombIndex = 0;
		for (AArenaBossBatBomb Bomb : Bombs)
		{
			Bomb.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			bool bDirectHit = false;
			if (BombIndex < 2)
				bDirectHit = true;
			TargetPlayer = TargetPlayer.OtherPlayer;
			Bomb.LaunchBomb(Boss, TargetPlayer, bDirectHit);
			BombIndex++;
		}
	}

	void ChargedUp() override
	{
		Super::ChargedUp();
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();

		Boss.ResetPlatforms();

		UArenaBossEffectEventHandler::Trigger_BatBombStateWindDown(Boss);
	}
}