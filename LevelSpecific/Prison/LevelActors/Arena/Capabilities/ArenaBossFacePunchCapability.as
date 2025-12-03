class UArenaBossFacePunchCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::FacePunch;
	default bResetToIdleOnDeactivation = false;

	default ChargeUpDuration = 0.0;

	EArenaBossFacePunchState CurrentState;

	float CurrentBigSmashTime = 0.0;
	float BigSmashDuration = 1.75;

	float CurrentFistOnGroundTime = 0.0;
	float FistOnGroundDuration = 8.0;

	float CurrentFacePunchTime = 0.0;
	float FacePunchDuration = 1.4;

	int CurrentPunchAmount = 0;
	int LoseHandAmount = 3;

	float CurrentBackToSmashTime = 0.0;
	float BackToSmashDuration = 1.0;

	float CurrentLoseHandTime = 0.0;
	float LoseHandDuration = 4.2;

	bool bTutorialCompleted = false;

	UDecalComponent ShadowDecalComp;
	AHazeActor TelegraphDecalActor;
	bool bHandLanded = false;

	float ForwardOffset = 3100.0;

	bool bPunchPhaseCompleted = false;

	// Bomb stuff for 2nd punch phase
	float BombInitialSpawnDelay = 1.0;
	float CurrentInitialBombSpawnTime = 0.0;
	bool bFirstBombSpawned = false;
	float BombDelay = 0.8;
	float CurrentBombTimer = 0.0;
	int MaxSocketIndex = 3;
	int CurrentSocketIndex = 0;
	AHazePlayerCharacter CurrentBombTarget;
	TArray<FName> SocketNames;
	default SocketNames.Add(n"LeftFrontLowerMissileSocket");
	default SocketNames.Add(n"LeftBackLowerMissileSocket");
	default SocketNames.Add(n"LeftFrontUpperMissileSocket");
	default SocketNames.Add(n"LeftBackUpperMissileSocket");

	bool bIncreasedViewSizeActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		CurrentState = EArenaBossFacePunchState::BigSmash;
		CurrentBigSmashTime = 0.0;
		CurrentFacePunchTime = 0.0;
		CurrentLoseHandTime = 0.0;

		CurrentBombTarget = Game::Mio;
		bFirstBombSpawned = false;
		CurrentInitialBombSpawnTime = 0.0;
		CurrentBombTimer = 0.0;
		CurrentSocketIndex = 0;
		
		bHandLanded = false;
		bIncreasedViewSizeActive = false;

		if (bPunchPhaseCompleted)
			CurrentPunchAmount = 0;

		Boss.AnimationData.bLosingHand = false;

		Boss.MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"MagnetBurst");

		// ShadowDecalComp = Decal::SpawnDecalAtLocation(Boss.SmashShadowMaterial, FVector(600.0), FVector::ZeroVector);
		TelegraphDecalActor = SpawnActor(Boss.TelegraphDecalClass);
		TelegraphDecalActor.SetActorScale3D(FVector(2.2));

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(Boss);
		Trace.UseLine();

		FVector TargetLoc = Boss.DefaultLocation;
		TargetLoc += Boss.ActorForwardVector * 3250;

		float RightOffset = 300.0;
		if (Boss.bRightHandRemoved)
			TargetLoc -= Boss.ActorRightVector * 80.0;
		else
			TargetLoc += Boss.ActorRightVector * 80.0;
		TargetLoc.Z = Boss.ActorLocation.Z;

		// ShadowDecalComp.SetWorldLocation(TargetLoc);
		TelegraphDecalActor.SetActorLocation(TargetLoc);

		Boss.EnableHandCollision();

		UArenaBossEffectEventHandler::Trigger_FacePunchStateEntered(Boss, GetEffectEventHandData());
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		if (!Game::Zoe.HasControl())
			return;

		if (!IsActive())
			return;

		if (CurrentState != EArenaBossFacePunchState::FistOnGround)
			return;

		FVector MagnetLocation = Boss.bRightHandRemoved ? Boss.LeftMagneticRoot.WorldLocation : Boss.RightMagneticRoot.WorldLocation;
		FVector Dir = (Data.ForceOrigin - MagnetLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FVector MagnetDir = Boss.bRightHandRemoved ? -Boss.LeftMagneticRoot.ForwardVector : -Boss.RightMagneticRoot.ForwardVector;
		float Dot = Dir.DotProduct(MagnetDir);

		if (Dot < 0.3)
			return;

		if (MagnetLocation.Dist2D(Game::Zoe.ActorCenterLocation, FVector::UpVector) >= 550.0)
			return;

		CrumbPunchFace();

		if (!bIncreasedViewSizeActive)
		{
			Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::AcceleratedFast);
			bIncreasedViewSizeActive = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Game::Zoe.RemoveTutorialPromptByInstigator(this);

		if (ShadowDecalComp != nullptr)
			ShadowDecalComp.DestroyComponent(this);

		if (TelegraphDecalActor != nullptr)
			TelegraphDecalActor.DestroyActor();

		Boss.AnimationData.bExitingFacePunch = false;
		Boss.AnimationData.bFacePunchFromSmash = false;

		ClearViewSize();

		UArenaBossEffectEventHandler::Trigger_FacePunchStateEnded(Boss, GetEffectEventHandData());
	}

	void ClearViewSize()
	{
		if (bIncreasedViewSizeActive)
		{
			bIncreasedViewSizeActive = false;
			Game::Zoe.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::AcceleratedFast);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, Boss.DefaultLocation, DeltaTime, 1600.0);
		Boss.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpConstantShortestPathTo(Boss.ActorRotation, FRotator(0.0, 180.0, 0.0), DeltaTime, 60.0);
		Boss.SetActorRotation(Rot);

		if (IsChargingUpOrWindingDown())
			return;

		if (CurrentState == EArenaBossFacePunchState::BigSmash)
		{
			FName KillSocket = Boss.bRightHandRemoved ? n"LeftHandInnerRing" : n"RightHandInnerRing";
			FVector HandLoc = Boss.Mesh.GetSocketLocation(KillSocket);

			CurrentBigSmashTime += DeltaTime;
			if (CurrentBigSmashTime >= BigSmashDuration)
			{
				// ShadowDecalComp.SetHiddenInGame(true);
				if (TelegraphDecalActor != nullptr)
					TelegraphDecalActor.DestroyActor();

				ReturnFistToGround();

				for (AHazePlayerCharacter Player : Game::GetPlayers())
				{
					FVector DirToHand = (Player.ActorLocation - HandLoc).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
					FVector KnockdownImpulse = DirToHand;
					Player.ApplyKnockdown(KnockdownImpulse, 1.5);

					FHazePointOfInterestFocusTargetInfo PoIInfo;
					PoIInfo.SetFocusToWorldLocation(HandLoc - (FVector::UpVector * 100.0));
					FApplyPointOfInterestSettings PoISettings;
					PoISettings.Duration = 0.5;
					Player.ApplyPointOfInterest(this, PoIInfo, PoISettings, 1.0);
				}
			}

			FRotator TraceRot = Boss.Mesh.GetSocketRotation(KillSocket);
			FHazeTraceSettings KillTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			KillTrace.UseBoxShape(300.0, 280.0, 200.0, FQuat(TraceRot));

			/*FHazeTraceDebugSettings Debug;
			Debug.Thickness = 20.0;
			Debug.TraceColor = FLinearColor::Red;
			KillTrace.DebugDraw(Debug);*/
			
			FOverlapResultArray OverlapResults = KillTrace.QueryOverlaps(HandLoc);
			for (FOverlapResult Result : OverlapResults)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
				if (Player != nullptr)
					Player.KillPlayer(FPlayerDeathDamageParams(FVector::DownVector), Boss.ImpactDeathEffect);
			}
		}

		if (CurrentState == EArenaBossFacePunchState::FistOnGround)
		{
			if (Game::Zoe.HasControl())
			{
				CurrentFistOnGroundTime += DeltaTime;
				if (CurrentFistOnGroundTime >= FistOnGroundDuration)
				{
					NetExitToSmash();
				}
			}
		}

		if (CurrentState == EArenaBossFacePunchState::PunchingFace)
		{
			CurrentFacePunchTime += DeltaTime;
			if (CurrentFacePunchTime >= FacePunchDuration)
				ReturnFistToGround();
		}

		if (CurrentState == EArenaBossFacePunchState::LosingHand)
		{
			FVector HandLoc = Boss.bRightHandRemoved ? Boss.LeftHandCollision.WorldLocation : Boss.RightHandCollision.WorldLocation;

			CurrentLoseHandTime += DeltaTime;
			if (CurrentLoseHandTime >= LoseHandDuration)
			{
				bPunchPhaseCompleted = true;
				Boss.ActivateState(EArenaBossState::HandRemoved);
			}

			if (CurrentLoseHandTime > 0.5 && CurrentLoseHandTime < 3.2)
			{
				FHazeTraceSettings KillTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				KillTrace.UseBoxShape(360.0, 300.0, 300.0, FQuat(FRotator::ZeroRotator));

				/*FHazeTraceDebugSettings Debug;
				Debug.Thickness = 20.0;
				Debug.TraceColor = FLinearColor::Red;
				KillTrace.DebugDraw(Debug);*/
				
				FOverlapResultArray OverlapResults = KillTrace.QueryOverlaps(HandLoc);
				for (FOverlapResult Result : OverlapResults)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
					if (Player != nullptr)
						Player.KillPlayer(FPlayerDeathDamageParams(FVector::DownVector), Boss.ImpactDeathEffect);
				}
			}

			if (CurrentLoseHandTime >= 3.0 && !bHandLanded)
			{
				bHandLanded = true;
				// ShadowDecalComp.DestroyComponent(this);
				if (TelegraphDecalActor != nullptr)
					TelegraphDecalActor.DestroyActor();

				ClearViewSize();
			}
		}

		if (CurrentState == EArenaBossFacePunchState::BackToSmash)
		{
			CurrentBackToSmashTime += DeltaTime;
			if (CurrentBackToSmashTime >= BackToSmashDuration)
			{
				bPunchPhaseCompleted = false;
				Boss.AnimationData.bSkipSmashEnter = true;
				Boss.AnimationData.bLeftHandSmash = !Boss.bRightHandRemoved;
				Boss.ActivateState(EArenaBossState::Smash);
			}
		}

		if (Boss.bRightHandRemoved && CurrentState != EArenaBossFacePunchState::BigSmash)
		{
			/*if (!bFirstBombSpawned)
			{
				CurrentInitialBombSpawnTime += DeltaTime;
				if (CurrentInitialBombSpawnTime >= BombInitialSpawnDelay)
					bFirstBombSpawned = true;

				return;
			}
			CurrentBombTimer += DeltaTime;
			if (CurrentBombTimer >= BombDelay)
			{
				LaunchBomb();
			}*/
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbPunchFace()
	{
		Boss.TakeDamage(1.0);

		RemoveTutorial();

		if (CurrentPunchAmount >= LoseHandAmount - 1)
		{
			Boss.AnimationData.bLosingHand = true;
			CurrentState = EArenaBossFacePunchState::LosingHand;

			FVector HandLandLoc = Boss.DefaultLocation;
			HandLandLoc -= FVector::ForwardVector * 3100.0;
			HandLandLoc -= FVector::RightVector * (Boss.bRightHandRemoved ? -850.0 : 850.0);

			// ShadowDecalComp = Decal::SpawnDecalAtLocation(Boss.SmashShadowMaterial, FVector(800.0), HandLandLoc);
			TelegraphDecalActor = SpawnActor(Boss.TelegraphDecalClass, HandLandLoc);
			TelegraphDecalActor.SetActorScale3D(FVector(2.0));

			Boss.EnableHandCollision();
			Boss.OnFinalMagnetPunch.Broadcast();

			UArenaBossEffectEventHandler::Trigger_FacePunchFinalHit(Boss, GetEffectEventHandData());

			Boss.OnFacePunched.Broadcast(!Boss.bRightHandRemoved, true);

			return;
		}
		else
		{
			CurrentFacePunchTime = 0.0;
			Boss.AnimationData.bPunchingFace = true;
			CurrentState = EArenaBossFacePunchState::PunchingFace;
			CurrentPunchAmount++;

			UArenaBossEffectEventHandler::Trigger_FacePunchHit(Boss, GetEffectEventHandData());
		}
		
		// if (!Boss.bRightHandRemoved)
		// {
			/*FHazePointOfInterestFocusTargetInfo PoIInfo;
			USceneComponent FocusComp = Boss.bRightHandRemoved ? Boss.LeftMagneticRoot : Boss.RightMagneticRoot;
			PoIInfo.SetFocusToComponent(FocusComp);
			PoIInfo.SetWorldOffset(FVector(400.0, 0.0, -1200.0));
			FApplyPointOfInterestSettings PoISettings;
			if (CurrentState == EArenaBossFacePunchState::LosingHand)
				PoISettings.Duration = 1.3;
			else
				PoISettings.Duration = 0.95;*/

			// Game::Zoe.ApplyPointOfInterest(this, PoIInfo, PoISettings, 0.2, EHazeCameraPriority::High);
			Boss.OnFacePunched.Broadcast(!Boss.bRightHandRemoved, false);
		// }
	}

	void RemoveTutorial()
	{
		if (!bTutorialCompleted)
		{
			bTutorialCompleted = true;
			Game::Zoe.RemoveTutorialPromptByInstigator(this);
		}
	}

	void ReturnFistToGround()
	{
		CurrentFistOnGroundTime = 0.0;
		Boss.AnimationData.bPunchingFace = false;
		CurrentState = EArenaBossFacePunchState::FistOnGround;

		if (!Boss.bRightHandRemoved && !bTutorialCompleted)
		{
			FTutorialPrompt TutorialPrompt;
			TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
			TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
			TutorialPrompt.Text = Boss.MagnetTutorialText;
			Game::Zoe.ShowTutorialPrompt(TutorialPrompt, this);
		}
	}

	UFUNCTION(NetFunction)
	void NetExitToSmash()
	{
		CurrentBackToSmashTime = 0.0;
		Boss.AnimationData.bExitingFacePunch = true;
		CurrentState = EArenaBossFacePunchState::BackToSmash;
	}

	void LaunchBomb()
	{
		CurrentBombTimer = 0.0;

		CurrentBombTarget = CurrentBombTarget.IsMio() ? Game::Zoe : Game::Mio;

		FName SpawnSocket = SocketNames[CurrentSocketIndex];

		FVector SpawnLoc = Boss.Mesh.GetSocketLocation(SpawnSocket);
		FRotator SpawnRot = Boss.Mesh.GetSocketRotation(SpawnSocket);
		FVector SpawnDir = SpawnRot.UpVector;

		AArenaBomb Bomb = SpawnActor(Boss.BombClass, SpawnLoc, SpawnDir.Rotation());

		Bomb.LaunchBomb(Boss, CurrentBombTarget, false);

		UArenaBossEffectEventHandler::Trigger_BombLaunched(Boss);

		CurrentSocketIndex++;
		if (CurrentSocketIndex > MaxSocketIndex)
			CurrentSocketIndex = 0;
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();
	}
}

enum EArenaBossFacePunchState
{
	BigSmash,
	FistOnGround,
	PunchingFace,
	LosingHand,
	BackToSmash
}