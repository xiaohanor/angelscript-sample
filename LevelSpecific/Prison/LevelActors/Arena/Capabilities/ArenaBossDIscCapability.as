class UArenaBossDiscCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::Disc;

	default ChargeUpDuration = 1.0;

	int PanelsLit = 0;

	int MaxDiscAmount = 24;
	int CurrentDiscAmount = 0;

	int DirectTargetInterval = 3;
	int CurrentDirectTarget = 0;

	bool bAligning = true;
	float StartAlignYaw = 0.0;
	float TargetAlignYaw = 0.0;
	float AlignDuration = 0.35;
	float CurrentAlignTime = 0.0;

	AHazePlayerCharacter TargetPlayer;

	float MinYaw = 155.0;
	float MaxYaw = 180.0;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		CurrentDiscAmount = 0;

		TargetPlayer = Game::Mio;
		StartAligning();

		UArenaBossEffectEventHandler::Trigger_DiscStateEntered(Boss);

		SetCameraChaseEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		UArenaBossEffectEventHandler::Trigger_DiscStateEnded(Boss);

		SetCameraChaseEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FVector TargetLoc = bWindingDown ? Boss.DefaultLocation : Boss.DefaultLocation - (FVector::UpVector * 170.0);
		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLoc, DeltaTime, 100.0);
		Boss.SetActorLocation(Loc);

		if (ActiveDuration >= PanelsLit * 0.75 && PanelsLit < 3)
			PanelsLit++;

		if (IsChargingUpOrWindingDown())
			return;

		if (bAligning)
		{
			CurrentAlignTime += DeltaTime;
			float YawAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, AlignDuration), FVector2D(0.0, 1.0), CurrentAlignTime);

			FRotator Rot = Math::LerpShortestPath(FRotator(0.0, StartAlignYaw, 0.0), FRotator(0.0, TargetAlignYaw, 0.0), YawAlpha);
			Boss.SetActorRotation(Rot);

			if (CurrentAlignTime >= AlignDuration)
				LaunchDisc();
		}
	}

	void StartAligning()
	{
		StartAlignYaw = Boss.ActorRotation.Yaw;
		CurrentAlignTime = 0.0;
		TargetPlayer = TargetPlayer.OtherPlayer;

		if (CurrentDirectTarget >= DirectTargetInterval - 1)
		{
			CurrentDirectTarget = 0;
			TargetAlignYaw = (TargetPlayer.ActorLocation - Boss.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector).Rotation().Yaw;
		}
		else
		{
			FVector PlayerVelocity = TargetPlayer.ActorHorizontalVelocity * 1.4;
			FVector TargetLocation = TargetPlayer.ActorLocation + PlayerVelocity;
			FVector DirToTargetLocation = (TargetLocation - Boss.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
			TargetAlignYaw = DirToTargetLocation.Rotation().Yaw;
			if (TargetAlignYaw > 0.0)
				TargetAlignYaw = Math::Clamp(TargetAlignYaw, MinYaw, MaxYaw);
			else
				TargetAlignYaw = Math::Clamp(TargetAlignYaw, -MaxYaw, -MinYaw);

			CurrentDirectTarget++;
		}

		bAligning = true;
	}

	void LaunchDisc()
	{
		Boss.SetAnimBoolParam(n"DiscLaunch", true);

		CurrentAlignTime = 0.0;

		FVector DiscSpawnLoc = Boss.Mesh.GetSocketLocation(n"ChestHatchLower");
		DiscSpawnLoc += (FVector::UpVector * 125.0);
		DiscSpawnLoc -= (Boss.ActorForwardVector * 300.0);

		AArenaBossDiscAttack Disc = SpawnActor(Boss.DiscClass, DiscSpawnLoc, Boss.ActorRotation);
		Disc.LaunchDisc();

		UArenaBossEffectEventHandler::Trigger_DiscLaunched(Boss);

		CurrentDiscAmount++;
		if (CurrentDiscAmount >= MaxDiscAmount)
			StartWindingDown();

		StartAligning();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(Boss.LightCameraShake, this, 0.35);
			Player.PlayForceFeedback(Boss.LightForceFeedback, false, true, this, 0.2);
		}
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();

		UArenaBossEffectEventHandler::Trigger_DiscStateWindDown(Boss);
	}
}