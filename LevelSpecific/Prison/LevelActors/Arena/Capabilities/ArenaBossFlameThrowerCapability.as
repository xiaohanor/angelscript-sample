class UArenaBossFlameThrowerCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::FlameThrower;

	default ChargeUpDuration = 5.0;
	default WindDownDuration = 1.0;

	bool bRightHand = true;

	bool bChargingSweep = false;
	float SweepChargeTime = 0.0;
	float SweepChargeDuration = 0.75;

	bool bSweeping = false;
	float CurrentSweepTime = 0.0;
	float SweepDuration = 6.6;

	bool bSwappingHands = false;
	float CurrentSwapHandsTime = 0.0;
	float SwapHandsDuration = 1.0;

	bool bInitialFlameActivated = false;
	bool bInitialFlameActive = false;

	int CurrentSweepAmount = 0;
	int MaxSweepAmount = 2;

	bool bStartedFlameThrowerOnRemote = false;
	float DelayStartFlameThrowerUntil = 0.0;
	bool bStartedFlameThrower = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bInitialFlameActivated = false;
		bRightHand = false;
		bSweeping = false;

		InitializeLaunchPads();

		UArenaBossEffectEventHandler::Trigger_FlameThrowerStateEntered(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		DisableLaunchPads();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.StopAllInstancesOfCameraShake(Boss.BombPassiveCameraShake);

		bRightHand = false;
		bStartedFlameThrower = false;
		bStartedFlameThrowerOnRemote = false;
		Boss.AnimationData.bSweepingFlameThrower = false;
		Boss.AnimationData.bFlameThrowerLeftHand = false;

		UArenaBossEffectEventHandler::Trigger_FlameThrowerStateEnded(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, FRotator(0.0, 180.0, 0.0), DeltaTime, 2.0);
		Boss.SetActorRotation(Rot);

		FVector TargetLoc = bWindingDown ? Boss.DefaultLocation : Boss.DefaultLocation - (FVector::UpVector * 200.0) + (FVector::ForwardVector * 400.0);
		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLoc, DeltaTime, 200.0);
		Boss.SetActorLocation(Loc);

		if (!bInitialFlameActivated && ActiveDuration >= 1.2)
			StartInitialFlame();

		if (IsChargingUpOrWindingDown())
			return;

		if (Network::IsGameNetworked())
		{
			if (!bStartedFlameThrower)
			{
				bStartedFlameThrower = true;
				DelayStartFlameThrowerUntil = Time::RealTimeSeconds + Network::PingOneWaySeconds;
				NetStartFlameThrower(Network::HasWorldControl());
			}

			if (!bStartedFlameThrowerOnRemote)
				return;
			if (Time::RealTimeSeconds < DelayStartFlameThrowerUntil)
				return;
		}

		FName CurrentSocket = bRightHand ? n"RightHandInnerRing" : n"LeftHandInnerRing";

		if (bChargingSweep)
		{
			SweepChargeTime += DeltaTime;
			if (SweepChargeTime >= SweepChargeDuration)
				StartSweeping();
		}

		else if (bSweeping)
		{
			FVector TraceLoc = Boss.Mesh.GetSocketLocation(CurrentSocket);
			FVector Dir = Boss.Mesh.GetSocketRotation(CurrentSocket).UpVector;
			Dir = Dir.ConstrainToPlane(FVector::UpVector);
			TraceLoc += Dir * 5000.0;
			TraceLoc -= FVector::UpVector * 200.0;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseBoxShape(5000.0, 150.0, 500.0, FQuat(Dir.Rotation()));

			/*FHazeTraceDebugSettings Debug;
			Debug.Thickness = 20.0;
			Debug.TraceColor = FLinearColor::Red;
			Trace.DebugDraw(Debug);*/

			FOverlapResultArray OverlapResults = Trace.QueryOverlaps(TraceLoc);
			for (FOverlapResult Result : OverlapResults)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
				if (Player != nullptr)
					Player.KillPlayer(FPlayerDeathDamageParams(Dir), Boss.FlameThrowerDeathEffect);
			}

			CurrentSweepTime += DeltaTime;
			if (CurrentSweepTime >= SweepDuration)
				FinishSweep();

			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.1;
				FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.1;
				Player.SetFrameForceFeedback(FF);
			}
		}

		else if (bSwappingHands)
		{
			CurrentSwapHandsTime += DeltaTime;
			if (CurrentSwapHandsTime >= SwapHandsDuration)
				ChargeSweep();
		}
	}

	UFUNCTION(NetFunction)
	void NetStartFlameThrower(bool bWorldControl)
	{
		if (bWorldControl != Network::HasWorldControl())
			bStartedFlameThrowerOnRemote = true;
	}

	void StartInitialFlame()
	{
		bInitialFlameActivated = true;
		bInitialFlameActive = true;

		FArenaBossFlameThrowerData Data;
		Data.bRightHand = true;
		UArenaBossEffectEventHandler::Trigger_FlameThrowerStarted(Boss, Data);
	}

	void ChargeSweep()
	{
		if (bChargingSweep)
			return;

		bRightHand = !bRightHand;

		SweepChargeTime = 0.0;
		bChargingSweep = true;

		if (!bInitialFlameActive)
		{
			FArenaBossFlameThrowerData Data;
			Data.bRightHand = bRightHand;
			UArenaBossEffectEventHandler::Trigger_FlameThrowerStarted(Boss, Data);
		}
		else
			bInitialFlameActive = false;

		Boss.AnimationData.bSweepingFlameThrower = false;
		Boss.AnimationData.bFlameThrowerLeftHand = bRightHand;
	}

	void StartSweeping()
	{
		if (bSweeping)
			return;

		CurrentSweepTime = 0.0;
		bSweeping = true;
		bChargingSweep = false;
		bSwappingHands = false;

		Boss.AnimationData.bSweepingFlameThrower = true;
	}

	void FinishSweep()
	{
		bSweeping = false;

		FArenaBossFlameThrowerData Data;
		Data.bRightHand = bRightHand;
		UArenaBossEffectEventHandler::Trigger_FlameThrowerStopped(Boss, Data);

		Boss.AnimationData.bSweepingFlameThrower = false;

		CurrentSweepAmount++;
		if (CurrentSweepAmount >= MaxSweepAmount)
		{
			StartWindingDown();
			return;
		}

		CurrentSwapHandsTime = 0.0;
		bSwappingHands = true;
	}

	void InitializeLaunchPads()
	{
		TListedActors<AArenaLaunchPad> LaunchPadList;
		TArray<AArenaLaunchPad> LaunchPads = LaunchPadList.GetArray();
		LaunchPads[0].Enable();
		LaunchPads[1].Enable();
	}

	void DisableLaunchPads()
	{
		TListedActors<AArenaLaunchPad> Pads;
		for (AArenaLaunchPad Pad : Pads)
		{
			Pad.ForceDisable();
		}
	}

	void ChargedUp() override
	{
		Super::ChargedUp();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayCameraShake(Boss.FlameThrowerCameraShake, this);

		ChargeSweep();
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();

		FArenaBossFlameThrowerData Data;
		Data.bRightHand = bRightHand;
		UArenaBossEffectEventHandler::Trigger_FlameThrowerStopped(Boss, Data);

		UArenaBossEffectEventHandler::Trigger_FlameThrowerStateWindDown(Boss);

		DisableLaunchPads();
	}
}