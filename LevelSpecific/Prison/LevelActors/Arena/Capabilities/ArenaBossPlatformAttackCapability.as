class UArenaBossPlatformAttackCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::PlatformAttack;

	default ChargeUpDuration = 0.5;

	AArenaPlatformManager PlatformManager;
	AHazePlayerCharacter TargetPlayer;
	AArenaPlatform TargetPlatform;

	float VerticalOffset = 4500.0;

	EArenaBossPlatformAttackState CurrentState;

	float CurrentFlyToPlatformDuration = 0.0;

	FHazeRuntimeSpline FlyDownSpline;
	float FlyDownSplineDistance = 0.0;
	float FlyDownSpeed = 2500.0;

	FHazeRuntimeSpline FlyUpSpline;
	float FlyUpSplineDistance = 0.0;
	float FlyUpSpeed = 2500.0;

	float FirstAttackChargeDuration = 1.5;
	float AttackChargeDuration = 0.5;
	float CurrentAttackChargeTime = 0.0;

	float AttackDuration = 0.7;
	float CurrentAttackTime = 0.0;

	int AttacksDone = 0;

	int AttacksBeforeSmashThroughMode = 6;
	int PlatformsSmashedThrough = 0;
	float SmashThroughChargeDuration = 1.0;
	float SmashThroughAttackDuration = 0.4;
	bool bSmashThroughModeActivated = false;

	bool bPlatformsReset = false;

	bool bFirstAttackTriggered = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		TargetPlayer = Game::Mio;
		PlatformManager = TListedActors<AArenaPlatformManager>().Single;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		CurrentState = EArenaBossPlatformAttackState::FlyingDown;

		FlyDownSplineDistance = 0.0;
		CurrentAttackChargeTime = 0.0;
		CurrentAttackTime = 0.0;
		AttacksDone = 0;
		bSmashThroughModeActivated = false;

		bPlatformsReset = false;
		Boss.SpreadPlatforms();

		Boss.OnPlatformAttackStarted.Broadcast();

		UArenaBossEffectEventHandler::Trigger_PlatformAttackStateEntered(Boss);

		FlyDownSpline.AddPoint(Boss.ActorLocation);
		FlyDownSpline.AddPoint(Boss.ActorTransform.TransformPosition(Boss.FlyDownSpline.Spline.SplinePoints[1].RelativeLocation));
		TargetPlatform = PlatformManager.GetCurrentPlayerPlatform(TargetPlayer);
		FVector TargetLoc = TargetPlatform.ImpactTargetComp.WorldLocation;
		TargetLoc.Z -= VerticalOffset;
		FlyDownSpline.AddPoint(TargetLoc);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		if (!bPlatformsReset)
		{
			Boss.ResetPlatforms();
			Boss.OnPlatformAttackEnded.Broadcast();
		}

		UArenaBossEffectEventHandler::Trigger_PlatformAttackStateEnded(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		Boss.AnimationData.PlatformAttackState = CurrentState;

		if (IsChargingUpOrWindingDown())
			return;

		if (CurrentState == EArenaBossPlatformAttackState::FlyingDown)
		{
			FlyDownSplineDistance += FlyDownSpeed * DeltaTime;
			FVector TargetLoc = FlyDownSpline.GetLocationAtDistance(FlyDownSplineDistance);
			Boss.SetActorLocation(TargetLoc);
			if (FlyDownSplineDistance >= FlyDownSpline.Length)
				StartFlyingToPlatform();
		}

		if (CurrentState == EArenaBossPlatformAttackState::FlyingToPlatform)
		{
			if (bSmashThroughModeActivated)
			{
				CurrentFlyToPlatformDuration += DeltaTime;
				FVector Platform1Loc = Boss.BreakablePlatforms[PlatformsSmashedThrough].ImpactTargetComp.WorldLocation;
				FVector Platform2Loc = Boss.BreakablePlatforms[PlatformsSmashedThrough + 1].ImpactTargetComp.WorldLocation;
				FVector TargetLoc = (Platform1Loc + Platform2Loc)/2.0;
				FVector DirBetweenPlatforms = (Platform1Loc - Platform2Loc).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				TargetLoc = Platform2Loc + (DirBetweenPlatforms * 650.0);
				TargetLoc.Z -= VerticalOffset;

				FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLoc, DeltaTime, 1.5);
				Boss.SetActorLocation(Loc);

				FRotator TargetRot = (Platform1Loc - Platform2Loc).GetSafeNormal().Rotation();
				if (PlatformsSmashedThrough >= 2)
					TargetRot.Yaw += 90.0;
				else
					TargetRot.Yaw -= 90.0;

				FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, TargetRot, DeltaTime, 2.0);
				Boss.SetActorRotation(Rot);

				if (Loc.Equals(TargetLoc, 80.0) && CurrentFlyToPlatformDuration >= 2.0)
					StartChargingAttack();
			}
			else
			{
				if (TargetPlatform == nullptr && PendingTargetPlatforms.Num() != 0)
				{
					TargetPlatform = PendingTargetPlatforms[0];
					TargetPlayer = PendingTargetPlayers[0];

					PendingTargetPlatforms.RemoveAt(0);
					PendingTargetPlayers.RemoveAt(0);
				}

				if (TargetPlatform != nullptr)
				{
					FVector TargetLoc = TargetPlatform.ImpactTargetComp.WorldLocation;
					TargetLoc.Z -= VerticalOffset;

					float FlySpeed = bSmashThroughModeActivated ? 2.5 : 1.5;

					FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLoc, DeltaTime, 2.5);
					Boss.SetActorLocation(Loc);
					if (Loc.Equals(TargetLoc, 80.0))
						StartChargingAttack();
				}
			}
		}

		if (CurrentState == EArenaBossPlatformAttackState::ChargingAttack)
		{
			CurrentAttackChargeTime += DeltaTime;
			if (AttacksDone == 0)
			{
				if (CurrentAttackChargeTime >= FirstAttackChargeDuration)
					TriggerAttack();
			}
			else if (CurrentAttackChargeTime >= AttackChargeDuration)
				TriggerAttack();
		}

		if (CurrentState == EArenaBossPlatformAttackState::Attacking || CurrentState == EArenaBossPlatformAttackState::SmashingThrough)
		{
			CurrentAttackTime += DeltaTime;
			if (CurrentAttackTime >= AttackDuration)
			{
				if (bSmashThroughModeActivated && PlatformsSmashedThrough >= 4)
				{
					if (CurrentAttackTime >= 1.0)
						FlyBackUp();

					return;
				}

				StartFlyingToPlatform();
			}
		}

		if (CurrentState == EArenaBossPlatformAttackState::Exiting)
		{
			FlyUpSplineDistance += FlyUpSpeed * DeltaTime;
			FVector TargetLoc = FlyUpSpline.GetLocationAtDistance(FlyUpSplineDistance);
			FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLoc, DeltaTime, 4.0);
			Boss.SetActorLocation(Loc);

			FRotator Rot = Math::RInterpConstantShortestPathTo(Boss.ActorRotation, FRotator(0.0, 180.0, 0.0), DeltaTime, 20.0);
			Boss.SetActorRotation(Rot);

			if (Loc.Equals(TargetLoc, 10.0))
				StartWindingDown();
		}
	}

	void StartFlyingToPlatform()
	{
		if (AttacksDone >= AttacksBeforeSmashThroughMode)
		{
			Boss.AnimationData.bPlatformBreakStateEnter = true;
			bSmashThroughModeActivated = true;
		}

		if (bSmashThroughModeActivated)
		{
			TargetPlatform = Boss.BreakablePlatforms[PlatformsSmashedThrough];
		}
		else
		{
			if (bFirstAttackTriggered)
				TargetPlayer = TargetPlayer.IsMio() ? Game::Zoe : Game::Mio;
			else
				bFirstAttackTriggered = true;

			if (TargetPlayer.HasControl())
			{
				AHazePlayerCharacter OriginalTargetPlayer = TargetPlayer;
				if (TargetPlayer.IsPlayerDead())
					TargetPlayer = TargetPlayer.OtherPlayer;

				TargetPlatform = PlatformManager.GetCurrentPlayerPlatform(TargetPlayer);
				NetStartFlyingToPlatform(OriginalTargetPlayer, TargetPlayer, TargetPlatform);
			}
			else
			{
				if (PendingTargetPlatforms.Num() != 0)
				{
					// Already received the target platform from the player's control side
					TargetPlatform = PendingTargetPlatforms[0];
					TargetPlayer = PendingTargetPlayers[0];

					PendingTargetPlatforms.RemoveAt(0);
					PendingTargetPlayers.RemoveAt(0);
				}
				else
				{
					// Haven't received the target platform yet, wait for it
					TargetPlatform = nullptr;
				}
			}
		}

		CurrentState = EArenaBossPlatformAttackState::FlyingToPlatform;

		UArenaBossEffectEventHandler::Trigger_PlatformAttackFlyToPlatformStarted(Boss);
	}

	TArray<AArenaPlatform> PendingTargetPlatforms;
	TArray<AHazePlayerCharacter> PendingTargetPlayers;

	UFUNCTION(NetFunction)
	void NetStartFlyingToPlatform(AHazePlayerCharacter FromPlayer, AHazePlayerCharacter NewTargetPlayer, AArenaPlatform Platform)
	{
		if (FromPlayer.HasControl())
			return;

		PendingTargetPlatforms.Add(Platform);
		PendingTargetPlayers.Add(NewTargetPlayer);
	}

	void StartChargingAttack()
	{
		CurrentAttackChargeTime = 0.0;
		
		if (bSmashThroughModeActivated)
		{
			AttackChargeDuration = SmashThroughChargeDuration;
			AttackDuration = SmashThroughAttackDuration;

			Boss.BreakablePlatforms[PlatformsSmashedThrough].PrepareAttack();
			Boss.BreakablePlatforms[PlatformsSmashedThrough + 1].PrepareAttack();
		}
		else
			TargetPlatform.PrepareAttack();

		CurrentState = EArenaBossPlatformAttackState::ChargingAttack;

		UArenaBossEffectEventHandler::Trigger_PlatformAttackChargeStarted(Boss);
	}

	void TriggerAttack()
	{
		CurrentFlyToPlatformDuration = 0.0;
		CurrentAttackTime = 0.0;
		
		if (bSmashThroughModeActivated)
		{
			Boss.BreakablePlatforms[PlatformsSmashedThrough].DestroyPlatform();
			Boss.BreakablePlatforms[PlatformsSmashedThrough + 1].DestroyPlatform();
			PlatformsSmashedThrough += 2;
			CurrentState = EArenaBossPlatformAttackState::SmashingThrough;

			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				Player.PlayCameraShake(Boss.HeavyCameraShake, this, 1.5);
				Player.PlayForceFeedback(Boss.MediumForceFeedback, false, true, this);
			}

			UArenaBossEffectEventHandler::Trigger_PlatformAttackSmashThrough(Boss);
		}
		else
		{
			AttacksDone++;
			CurrentState = EArenaBossPlatformAttackState::Attacking;

			TargetPlatform.TriggerAttack();

			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				Player.PlayCameraShake(Boss.HeavyCameraShake, this);
				Player.PlayForceFeedback(Boss.HeavyForceFeedback, false, true, this);
			}

			UArenaBossEffectEventHandler::Trigger_PlatformAttackHit(Boss);
		}
	}

	void FlyBackUp()
	{
		FlyUpSpline.AddPoint(Boss.ActorLocation);
		FlyUpSpline.AddPoint(Boss.FlyDownSpline.ActorTransform.TransformPosition(Boss.FlyDownSpline.Spline.SplinePoints[1].RelativeLocation));
		FVector TargetLoc = Boss.DefaultLocation;
		FlyUpSpline.AddPoint(TargetLoc);

		CurrentState = EArenaBossPlatformAttackState::Exiting;
		Boss.AnimationData.bExitingState = true;

		bPlatformsReset = true;
		Boss.ResetPlatforms();

		Boss.OnPlatformAttackEnded.Broadcast();

		UArenaBossEffectEventHandler::Trigger_PlatformAttackReturnStarted(Boss);
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();
		UArenaBossEffectEventHandler::Trigger_PlatformAttackStateWindDown(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("CurrentState", CurrentState);
		TemporalLog.Value("AttacksDone", AttacksDone);
		TemporalLog.Value("bChargedUp", bChargedUp);
		TemporalLog.Value("bWindingDown", bWindingDown);
		TemporalLog.Value("TargetPlayer", TargetPlayer);
		TemporalLog.Value("TargetPlatform", TargetPlatform);
	}
}

enum EArenaBossPlatformAttackState
{
	FlyingDown,
	FlyingToPlatform,
	ChargingAttack,
	Attacking,
	SmashingThrough,
	Exiting
}