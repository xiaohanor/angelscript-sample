class UArenaBossRocketPunchCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::RocketPunch;

	default WindDownDuration = 1.0;

	AHazePlayerCharacter TargetPlayer;
	FVector TargetLocation;

	bool bLockingOn = true;
	float LockOnDuration = 0.5;
	float CurrentLockOnTime = 0.0;

	bool bCharging = false;
	float ChargeDuration = 0.1;
	float CurrentChargeTime = 0.0;

	bool bPunching = false;
	float PunchDuration = 3.15;
	float CurrentPunchTime = 0.0;

	int MaxPunchAmount = 4;
	int CurrentPunchAmount = 0;

	FName SocketName = n"RightHandDeform";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		TargetPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bLockingOn = true;

		UArenaBossEffectEventHandler::Trigger_RocketPunchStateEntered(Boss);

		bLockingOn = true;
		bCharging = false;
		bPunching = false;

		CurrentLockOnTime = 0.0;
		CurrentChargeTime = 0.0;
		CurrentPunchTime = 0.0;

		CurrentPunchAmount = 0;

		// SetCameraChaseEnabled(false);

		SetBossCameraCollisionEnabled(false);

		Boss.BP_RocketPunchTargeting();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		UArenaBossEffectEventHandler::Trigger_RocketPunchStateEnded(Boss);

		SetCameraChaseEnabled(true);

		SetBossCameraCollisionEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (bWindingDown)
		{
			FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, Boss.DefaultLocation, DeltaTime, 900.0);
			Boss.SetActorLocation(Loc);
		}
		else
		{
			FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, Boss.DefaultLocation + FVector::ForwardVector * 1200.0, DeltaTime, 800.0);
			Boss.SetActorLocation(Loc);
		}

		if (IsChargingUpOrWindingDown())
			return;

		if (bLockingOn)
		{
			FVector DirToPlayer = (TargetPlayer.ActorLocation - Boss.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
			FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 8.0);
			Boss.SetActorRotation(Rot);

			CurrentLockOnTime += DeltaTime;
			if (CurrentLockOnTime >= LockOnDuration)
				StartChargingPunch();

			// Debug::DrawDebugLine(Boss.Mesh.GetSocketLocation(SocketName), Boss.Mesh.GetSocketLocation(SocketName) + (Boss.Mesh.GetSocketRotation(SocketName).UpVector * 10000.0), FLinearColor::Red, 20.0);
		}

		if (bCharging)
		{
			CurrentChargeTime += DeltaTime;
			if (CurrentChargeTime >= ChargeDuration)
				TriggerPunch();
		}

		if (bPunching)
		{
			FRotator TraceRot = Boss.Mesh.GetSocketRotation(SocketName);
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.UseBoxShape(150.0, 400.0, 400.0, FQuat(TraceRot));

			/*FHazeTraceDebugSettings Debug;
			Debug.Thickness = 20.0;
			Debug.TraceColor = FLinearColor::Red;
			Trace.DebugDraw(Debug);*/
			
			FVector TraceLoc = Boss.Mesh.GetSocketLocation(SocketName);
			TraceLoc += TraceRot.UpVector * 200.0;
			TraceLoc += TraceRot.ForwardVector * 50.0;
			FOverlapResultArray OverlapResults = Trace.QueryOverlaps(TraceLoc);
			for (FOverlapResult Result : OverlapResults)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
				if (Player != nullptr)
				{
					FVector KillDir = TraceRot.ForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
					Player.KillPlayer(FPlayerDeathDamageParams(KillDir, 5.0), Boss.ImpactDeathEffect);
				}
			}

			CurrentPunchTime += DeltaTime;
			if (CurrentPunchTime >= PunchDuration)
			{
				Boss.AnimationData.bLaunchingFist = false;

				if (CurrentPunchAmount >= MaxPunchAmount)
					StartWindingDown();
				else
					LockOn();
			}
		}
	}

	void LockOn()
	{
		if (bPunching)
			UArenaBossEffectEventHandler::Trigger_RocketPunchReturned(Boss);

		if (!TargetPlayer.OtherPlayer.IsPlayerDead())
			TargetPlayer = TargetPlayer.OtherPlayer;

		CurrentLockOnTime = 0.0;
		bPunching = false;
		bLockingOn = true;

		UArenaBossEffectEventHandler::Trigger_RocketPunchLockOnStarted(Boss);

		Boss.BP_RocketPunchTargeting();
	}

	void StartChargingPunch()
	{
		FVector HandLocation;

		bLockingOn = false;
		bCharging = true;
		CurrentChargeTime = 0.0;

		UArenaBossEffectEventHandler::Trigger_RocketPunchChargeStarted(Boss);
	}

	void TriggerPunch()
	{
		UArenaBossEffectEventHandler::Trigger_RocketPunchLaunched(Boss);

		Boss.AnimationData.bLaunchingFist = true;

		bCharging = false;
		bPunching = true;
		CurrentPunchTime = 0.0;

		CurrentPunchAmount++;

		Boss.BP_RocketPunchLaunched();
	}

	void ChargedUp() override
	{
		Super::ChargedUp();
		UArenaBossEffectEventHandler::Trigger_RocketPunchLockOnStarted(Boss);
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();
		UArenaBossEffectEventHandler::Trigger_RocketPunchStateWindDown(Boss);
	}
}