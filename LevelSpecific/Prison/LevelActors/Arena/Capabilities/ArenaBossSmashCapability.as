class UArenaBossSmashCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::Smash;
	default ChargeUpDuration = 1.0;
	default WindDownDuration = 0.2;

	AHazePlayerCharacter TargetPlayer;
	FVector TargetLocation;

	bool bLockingOn = true;
	float LockOnDuration = 1.5;
	float CurrentLockOnTime = 0.0;

	bool bCharging = false;
	float ChargeDuration = 0.6;
	float CurrentChargeTime = 0.0;

	bool bSmashing = false;
	float SmashDuration = 1.0;
	float CurrentSmashTime = 0.0;

	bool bRightSmash = true;

	int MaxSmashAmount = 4;
	int CurrentSmashAmount = 0;

	UDecalComponent ShadowDecalComp;
	AHazeActor TelegraphActor;
	bool bTelegraphDecalSpawned = false;

	FVector Offset = FVector(2800.0, 350.0, 0.0);

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bLockingOn = true;
		bCharging = false;
		bSmashing = false;
		bRightSmash = false;
		if (Boss.bRightHandRemoved)
			bRightSmash = true;

		UArenaBossEffectEventHandler::Trigger_SmashStateEntered(Boss);

		TargetPlayer = Game::Mio;

		CurrentSmashAmount = 0;
		CurrentLockOnTime = 0.0;
		CurrentChargeTime = 0.0;
		CurrentSmashTime = 0.0;

		// ShadowDecalComp = Decal::SpawnDecalAtLocation(Boss.SmashShadowMaterial, FVector(400.0), FVector::ZeroVector);

		Boss.DisableBothHandCollisions();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		// ShadowDecalComp.SetHiddenInGame(true);
		if (TelegraphActor != nullptr)
			TelegraphActor.DestroyActor();
		bTelegraphDecalSpawned = false;

		Boss.AnimationData.bLeftHandSmash = true;
		if (Boss.bRightHandRemoved)
			Boss.AnimationData.bLeftHandSmash = false;

		Boss.AnimationData.bSmashing = false;

		UArenaBossEffectEventHandler::Trigger_SmashStateEnded(Boss);

		Boss.AnimationData.bFacePunchFromSmash = true;
		Boss.ActivateState(EArenaBossState::FacePunch);

		SetBossCameraCollisionEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, FRotator(0.0, 180.0, 0.0), DeltaTime, 2.0);
		Boss.SetActorRotation(Rot);

		if (IsChargingUpOrWindingDown())
			return;

		FName Socket = bRightSmash ? n"LeftHandPinky1" : n"RightHandPinky1";
		FVector FistOffset = Offset;
		if (bRightSmash)
			FistOffset.Y = -Offset.Y;

		if (bLockingOn)
		{
			FVector PlayerLoc = TargetPlayer.ActorLocation;

			FVector TargetLoc = PlayerLoc + FistOffset;
			TargetLoc.Z = Boss.ActorLocation.Z;

			float InterpSpeed = Math::GetMappedRangeValueClamped(FVector2D(600.0, 100.0), FVector2D(2000.0, 550.0), Boss.ActorLocation.Dist2D(TargetLoc, FVector::UpVector));

			FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLoc, DeltaTime, InterpSpeed);
			Boss.SetActorLocation(Loc);

			CurrentLockOnTime += DeltaTime;
			if (CurrentLockOnTime >= LockOnDuration)
				StartChargingSmash();
		}

		if (bCharging)
		{
			CurrentChargeTime += DeltaTime;
			if (CurrentChargeTime >= ChargeDuration)
				TriggerSmash();
		}

		if (bSmashing)
		{
			CurrentSmashTime += DeltaTime;
			if (CurrentSmashTime >= SmashDuration)
			{
				if (CurrentSmashAmount >= MaxSmashAmount)
					StartWindingDown();
				else
					LockOn();

				return;
			}

			if (CurrentSmashTime <= 0.4)
			{
				FName KillSocket = bRightSmash ? n"RightHandDeform" : n"LeftHandDeform";
				if (Boss.bRightHandRemoved)
					KillSocket = n"LeftHandDeform";
				FRotator TraceRot = Boss.Mesh.GetSocketRotation(KillSocket);
				FHazeTraceSettings KillTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				KillTrace.UseBoxShape(200.0, 320.0, 400.0, FQuat(TraceRot));

				/*FHazeTraceDebugSettings Debug;
				Debug.Thickness = 20.0;
				Debug.TraceColor = FLinearColor::Red;
				KillTrace.DebugDraw(Debug);*/
				
				FVector TraceLoc = Boss.Mesh.GetSocketLocation(KillSocket);
				TraceLoc += TraceRot.UpVector * 200.0;
				TraceLoc += TraceRot.ForwardVector * 50.0;
				FOverlapResultArray OverlapResults = KillTrace.QueryOverlaps(TraceLoc);
				for (FOverlapResult Result : OverlapResults)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
					if (Player != nullptr)
						Player.KillPlayer(FPlayerDeathDamageParams(FVector::DownVector), Boss.ImpactDeathEffect);
				}
			}
			else
			{
				if (bTelegraphDecalSpawned)
				{
					bTelegraphDecalSpawned = false;
					if (TelegraphActor != nullptr)
						TelegraphActor.DestroyActor();
				}
			}
		}

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(Boss);
		Trace.UseLine();

		FVector TargetLoc = Boss.ActorLocation;
		TargetLoc += Boss.ActorForwardVector * FistOffset.X;
		TargetLoc += Boss.ActorRightVector * FistOffset.Y;
		TargetLoc.Z = Boss.ActorLocation.Z;

		FVector TraceStartLoc = TargetLoc + (FVector::UpVector * 2000.0);
		FHitResult Hit = Trace.QueryTraceSingle(TraceStartLoc, TraceStartLoc - (FVector::UpVector * 4000.0));

		if (bLockingOn)
		{
			if (Hit.bBlockingHit)
			{
				// ShadowDecalComp.SetHiddenInGame(false);
				// ShadowDecalComp.SetWorldLocation(Hit.ImpactPoint);
				if (TelegraphActor != nullptr)
					TelegraphActor.SetActorLocation(Hit.ImpactPoint);
			}
			else
			{
				// ShadowDecalComp.SetHiddenInGame(true);
			}
		}
	}

	void LockOn()
	{
		if (!TargetPlayer.OtherPlayer.IsPlayerDead())
			TargetPlayer = TargetPlayer.OtherPlayer;

		CurrentLockOnTime = 0.0;
		bLockingOn = true;
		bSmashing = false;

		Boss.AnimationData.bLeftHandSmash = !bRightSmash;
		Boss.AnimationData.bSmashing = false;

		UArenaBossEffectEventHandler::Trigger_SmashLockOnStarted(Boss);

		TelegraphActor = SpawnActor(Boss.TelegraphDecalClass);
		TelegraphActor.SetActorScale3D(FVector(2.0));
		bTelegraphDecalSpawned = true;

		SetBossCameraCollisionEnabled(true);
	}

	void StartChargingSmash()
	{
		bCharging = true;
		bLockingOn = false;
		CurrentChargeTime = 0.0;

		UArenaBossEffectEventHandler::Trigger_SmashChargeStarted(Boss);
	}

	void TriggerSmash()
	{
		bSmashing = true;
		bCharging = false;
		CurrentSmashTime = 0.0;
		
		if (!Boss.bRightHandRemoved)
			bRightSmash = !bRightSmash;

		Boss.AnimationData.bSmashing = true;

		CurrentSmashAmount++;

		SetBossCameraCollisionEnabled(false);

		UArenaBossEffectEventHandler::Trigger_SmashAttack(Boss);

		// if (CurrentSmashAmount >= MaxSmashAmount)
			// StartWindingDown();
	}

	void ChargedUp() override
	{
		LockOn();

		Super::ChargedUp();
		UArenaBossEffectEventHandler::Trigger_SmashLockOnStarted(Boss);
	}
	
	void StartWindingDown() override
	{
		Super::StartWindingDown();

		if (ShadowDecalComp != nullptr)
			ShadowDecalComp.SetHiddenInGame(true);

		if (TelegraphActor != nullptr)
			TelegraphActor.DestroyActor();

		SetBossCameraCollisionEnabled(true);

		UArenaBossEffectEventHandler::Trigger_SmashStateWindDown(Boss);
	}
}