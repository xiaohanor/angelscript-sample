class UArenaBossLaserEyesCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::LaserEyes;
	default bResetToIdleOnDeactivation = false;

	default ChargeUpDuration = 1.0;

	bool bReachedPlatform = false;

	bool bSweepingLeft = true;

	float SplineDist = 0.0;

	UHazeSplineComponent SplineComp;

	float SweepDuration = 3.0;
	float CurrentSweepTime = 0.0;
	float DurationDecreasePerSweep = 0.25;
	float MinDuration = 1.2;
	float MaxDuration = 3.0;

	float ActivateLaserTime = 0.0;
	float ActivateLaserDuration = 1.2;
	bool bLaserActivated = false;

	int TotalSpins = 0;
	int MaxSpins = 12;

	bool bOverHeating = false;
	float CurrentOverHeatTime = 0.0;
	float OverHeatDuration = 12.0;
	float MinOverHeatSpinSpeed = 180.0;
	float MaxOverHeatSpinSpeed = 360.0;
	FVector2D IntermittentExplosionIntervalRange = FVector2D(2.0, 4.0);
	float IntermittentExplosionInterval = 2.0;
	float LastIntermittentExplosionIntervalTime = 0.0;
	bool bOverHeated = false;

	bool bStartedLaserOnRemote = false;
	float DelayStartLaserUntil = 0.0;
	bool bStartedLaser = false;

	FVector DefaultLoc;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		SplineComp = Boss.LaserEyesMoveSpline.Spline;
		bStartedLaser = false;

		Boss.HeadActor.SetActorEnableCollision(true);

		SetCameraChaseEnabled(false);

		Boss.Mesh.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
		Boss.HeadActor.SetActorHiddenInGame(false);

		UArenaBossEffectEventHandler::Trigger_LaserEyesStateEntered(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.StopAllInstancesOfCameraShake(Boss.BombPassiveCameraShake);

		bSweepingLeft = false;
		bStartedLaserOnRemote = false;

		if (!bOverHeated)
			Boss.BP_DeactivateLaserEyes();

		SetCameraChaseEnabled(true);

		UArenaBossEffectEventHandler::Trigger_LaserEyesStateEnded(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (!bReachedPlatform)
		{
			SplineDist = Math::Clamp(SplineDist + 2500.0 * DeltaTime, 0.0, Boss.LaserEyesMoveSpline.Spline.SplineLength);
			FVector TargetLoc = SplineComp.GetWorldLocationAtSplineDistance(SplineDist);
			FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLoc, DeltaTime, 8.0);
			Boss.SetActorLocation(Loc);

			float Rot = Math::Lerp(180.0, 0.0, SplineDist/SplineComp.SplineLength);
			Boss.SetActorRotation(FRotator(0.0, Rot, 0.0));

			if (Loc.Equals(TargetLoc))
				ReachedPlatform();

			return;
		}	

		if (IsChargingUpOrWindingDown())
			return;

		if (Network::IsGameNetworked())
		{
			if (!bStartedLaserOnRemote)
				return;
			if (Time::RealTimeSeconds < DelayStartLaserUntil)
				return;
		}

		if (!bStartedLaser)
		{
			Boss.AnimationData.bInPositionForLaser = true;
			bStartedLaser = true;
		}

		if (!bLaserActivated)
		{
			ActivateLaserTime += DeltaTime;
			if (ActivateLaserTime >= ActivateLaserDuration)
				ActivateLaser();

			return;
		}

		if (bOverHeated)
		{
			FRotator HeadRot = Math::RInterpShortestPathTo(Boss.HeadActor.ActorRelativeRotation, FRotator(0.0, 180.0, 0.0), DeltaTime, 2.0);
			Boss.HeadActor.SetActorRelativeRotation(HeadRot);

			FVector TargetLoc = DefaultLoc + (Boss.ActorForwardVector * 500.0);
			TargetLoc.Z += 550.0;
			FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLoc, DeltaTime, 300.0);
			Boss.SetActorLocation(Loc);
			return;
		}
		else if (bOverHeating)
		{
			CurrentOverHeatTime += DeltaTime;
			if (CurrentOverHeatTime >= OverHeatDuration)
				FullyOverHeated();

			float SpinSpeed = Math::Lerp(MinOverHeatSpinSpeed, MaxOverHeatSpinSpeed, CurrentOverHeatTime/OverHeatDuration);
			Boss.HeadActor.AddActorLocalRotation(FRotator(0.0, SpinSpeed * DeltaTime, 0.0));
		}

		if (ActiveDuration > LastIntermittentExplosionIntervalTime + IntermittentExplosionInterval)
		{
			LastIntermittentExplosionIntervalTime = ActiveDuration;
			IntermittentExplosionInterval = Math::RandRange(IntermittentExplosionIntervalRange.X, IntermittentExplosionIntervalRange.Y);
			Boss.HeadActor.TriggerIntermittentExplosion();
		}

		FVector TraceLoc = Boss.HeadActor.ActorLocation;
		FVector Dir = Boss.HeadActor.ActorForwardVector;
		Dir = Dir.ConstrainToPlane(FVector::UpVector);
		TraceLoc += FVector::UpVector * 210.0;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			bool bPlayerNearLaser = Math::LineSphereIntersection(TraceLoc, Dir, 4000.0, Player.ActorCenterLocation, 1000.0);
			if (bPlayerNearLaser)
				Player.SetFrameForceFeedback(0.5, 0.5, 0.0, 0.0);
		}

		TraceLoc += Dir * 2000.0;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseBoxShape(2000.0, 80.0, 10.0, FQuat(Dir.Rotation()));

		/*FHazeTraceDebugSettings Debug;
		Debug.Thickness = 20.0;
		Debug.TraceColor = FLinearColor::Red;
		Trace.DebugDraw(Debug);*/

		FOverlapResultArray OverlapResults = Trace.QueryOverlaps(TraceLoc);
		for (FOverlapResult Result : OverlapResults)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
			if (Player != nullptr)
			{
				FVector DeathDirection = bSweepingLeft ? -Boss.HeadActor.ActorRightVector : Boss.HeadActor.ActorRightVector;
				Player.DamagePlayerHealth(1.0/3.0, FPlayerDeathDamageParams(DeathDirection), Boss.LaserDamageEffect, Boss.LaserDeathEffect);
			}
		}

		if (!bOverHeated && !bOverHeating)
		{
			CurrentSweepTime += DeltaTime;
			if (CurrentSweepTime >= SweepDuration)
				ChangeDirection();
		}
	}

	void ReachedPlatform()
	{
		bReachedPlatform = true;
		DefaultLoc = Boss.ActorLocation;

		UArenaBossEffectEventHandler::Trigger_LaserEyesAttackStarted(Boss);

		if (Network::IsGameNetworked())
		{
			DelayStartLaserUntil = Time::RealTimeSeconds + Network::PingOneWaySeconds;
			NetReachedPlatform(Network::HasWorldControl());
		}
	}

	UFUNCTION(NetFunction)
	void NetReachedPlatform(bool bWorldControl)
	{
		if (bWorldControl != Network::HasWorldControl())
			bStartedLaserOnRemote = true;
	}

	void ActivateLaser()
	{
		if (bLaserActivated)
			return;

		bLaserActivated = true;
		Boss.BP_ActivateLaserEyes();

		FArenaBossLaserEyesSweepData Data;
		Data.CompletionAlpha = 0.0;
		UArenaBossEffectEventHandler::Trigger_LaserEyesSweepStarted(Boss, Data);
	}

	void ChangeDirection()
	{
		TotalSpins++;
		Boss.LaserEyesSpins = TotalSpins;
		if (TotalSpins >= MaxSpins)
		{
			IntermittentExplosionIntervalRange = FVector2D(0.5, 1.0);
			Boss.BP_StartOverHeating();
			Boss.Mesh.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);
			Boss.HeadActor.SetActorHiddenInGame(false);
			bOverHeating = true;
			return;
		}

		CurrentSweepTime = 0.0;
		SweepDuration = Math::Clamp(SweepDuration - DurationDecreasePerSweep, MinDuration, MaxDuration);
		bSweepingLeft = !bSweepingLeft;
		Boss.AnimationData.bLaserLeft = bSweepingLeft;

		float PlayRate = Boss.LaserEyesPlayRateCurve.GetFloatValue(SweepDuration);
		Boss.AnimationData.LaserPlayRate = PlayRate;

		FArenaBossLaserEyesSweepData Data;
		Data.CompletionAlpha = Math::TruncToFloat(TotalSpins)/Math::TruncToFloat(MaxSpins);
		UArenaBossEffectEventHandler::Trigger_LaserEyesSweepStarted(Boss, Data);
	}

	void FullyOverHeated()
	{
		if (bOverHeated)
			return;

		bOverHeated = true;
		Boss.AnimationData.bLaserOverheat = true;
		Timer::SetTimer(this, n"AllowHacking", 4.5);
		UArenaBossEffectEventHandler::Trigger_LaserEyesOverheat(Boss);
	}

	UFUNCTION()
	private void AllowHacking()
	{
		Boss.BP_DeactivateLaserEyes();
		Boss.ActivateState(EArenaBossState::HeadHack);
	}

	void ChargedUp() override
	{
		Super::ChargedUp();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayCameraShake(Boss.FlameThrowerCameraShake, this);
	}

	void StartWindingDown() override
	{
		Super::StartWindingDown();

		UArenaBossEffectEventHandler::Trigger_FlameThrowerStateWindDown(Boss);
	}
}