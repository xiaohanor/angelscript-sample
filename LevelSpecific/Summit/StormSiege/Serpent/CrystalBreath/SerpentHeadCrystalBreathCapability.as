class USerpentHeadCrystalBreathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASerpentHead Serpent;
	AHazePlayerCharacter PlayerTarget;

	USerpentCrystalBreathComponent BreathComp;

	FHazePlaySlotAnimationParams EnterSlotAnimationParams;
	FHazePlaySlotAnimationParams MainSlotAnimationParams;
	FHazePlaySlotAnimationParams ExitSlotAnimationParams;

	FHazeAcceleratedFloat AccInterpSpeed;

	FRotator ShootRotation;

	FVector CurrentShootLocation;
	FVector StartShootLocation;
	FVector EndTargetLocation;

	const float SweepDistance = 30000.0;

	const float WaterfallDistanceToSweepCenter = 20000;
	const float IntroBreathDistance = 70000.0;
	const float WaterFallBreathDistance = WaterfallDistanceToSweepCenter + 100000;

	const float WaterFallShootDuration = 5;
	const float IntroShootDuration = 3;

	float ShootDuration;

	float BreathDistance = 0;
	float TimeStartedShooting = 0;

	bool bIsPlayingMainSlotAnim = false;
	bool bIsShooting = false;
	bool bHasSwitchedTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Serpent = Cast<ASerpentHead>(Owner);
		BreathComp = USerpentCrystalBreathComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Serpent.bRunCrystalBreathAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Serpent.bRunCrystalBreathAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasSwitchedTarget = false;
		bIsShooting = false;
		bIsPlayingMainSlotAnim = false;
		PlayerTarget = Game::Zoe;
		float DelayBeforeShooting;
		if (Serpent.bUseCrystalBreathAnimsInWaterfall)
		{
			EnterSlotAnimationParams = BreathComp.WaterfallEnterSequenceParams;
			MainSlotAnimationParams = BreathComp.WaterfallMainSequenceParams;
			ExitSlotAnimationParams = BreathComp.WaterfallExitSequenceParams;
			DelayBeforeShooting = BreathComp.WaterfallDelayBeforeShooting;
		}
		else
		{
			EnterSlotAnimationParams = BreathComp.EnterSequenceParams;
			MainSlotAnimationParams = BreathComp.MainSequenceParams;
			ExitSlotAnimationParams = BreathComp.ExitSequenceParams;
			DelayBeforeShooting = BreathComp.DelayBeforeShooting;
		}

		FTransform JawTransform = Serpent.SkeletalMeshBeast.GetSocketTransform(n"Jaw");
		USerpentHeadEffectHandler::Trigger_StartCrystalBreath(Serpent, FSerpentHeadCrystalBreathParams(JawTransform.Location, JawTransform.Location, JawTransform.Rotation, JawTransform.Location));
		Timer::SetTimer(this, n"StartShooting", DelayBeforeShooting);
	}

	UFUNCTION()
	private void StartShooting()
	{
		if (HasControl())
		{
			FVector ToZoe = Game::Zoe.ActorLocation - Serpent.ActorLocation;
			FVector PlaneLocation = Serpent.ActorLocation + ToZoe;
			FVector MioLocOnPlane = Game::Mio.ActorLocation.PointPlaneProject(PlaneLocation, Serpent.ActorForwardVector);
			FVector ZoeLocOnPlane = Game::Zoe.ActorLocation.PointPlaneProject(PlaneLocation, Serpent.ActorForwardVector);
			FVector SweepCenter = ZoeLocOnPlane;
			FVector SweepDirection = (MioLocOnPlane - ZoeLocOnPlane).GetSafeNormal();
			BreathDistance = IntroBreathDistance;
			ShootDuration = IntroShootDuration;
			if (Serpent.bUseCrystalBreathAnimsInWaterfall)
			{
				BreathDistance = WaterFallBreathDistance;
				SweepCenter = Serpent.ActorLocation - Serpent.CurrentSplinePosition.WorldForwardVector * WaterfallDistanceToSweepCenter;
				SweepDirection = Serpent.CurrentSplinePosition.WorldUpVector;
				ShootDuration = WaterFallShootDuration;
			}

			CrumbSetShootParams(SweepCenter, SweepDirection, BreathDistance, ShootDuration);
		}
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayCameraShake(Serpent.CrystalBreathCamShake, this);

	}

	UFUNCTION(CrumbFunction)
	void CrumbSetShootParams(FVector SweepCenter, FVector SweepDirection, float InBreathDistance, float InShootDuration)
	{
		FTransform JawTransform = Serpent.SkeletalMeshBeast.GetSocketTransform(n"Jaw", ERelativeTransformSpace::RTS_Actor);
		BreathDistance = InBreathDistance;
		FVector StartLocationWorldSpace = SweepCenter - (SweepDirection * SweepDistance * 0.35);
		StartShootLocation = Serpent.ActorTransform.InverseTransformPositionNoScale(SweepCenter - (SweepDirection * SweepDistance * 0.35));
		CurrentShootLocation = StartShootLocation;
		EndTargetLocation = Serpent.ActorTransform.InverseTransformPositionNoScale(SweepCenter + (SweepDirection * SweepDistance * 0.65));
		ShootRotation = FRotator::MakeFromX(CurrentShootLocation - JawTransform.Location);
		bIsShooting = true;
		TimeStartedShooting = Time::GameTimeSeconds;
		ShootDuration = InShootDuration;
		USerpentHeadEffectHandler::Trigger_StartShooting(Serpent, FSerpentHeadCrystalBreathParams(JawTransform.Location, StartLocationWorldSpace, ShootRotation.Quaternion(), StartLocationWorldSpace));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.StopCameraShakeByInstigator(this);

		USerpentHeadEffectHandler::Trigger_StopCrystalBreath(Serpent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector StartLocation = Serpent.SkeletalMeshBeast.GetSocketLocation(n"Jaw");

		if (!bIsShooting)
		{
			return;
		}

		float Alpha = Math::Saturate(Time::GetGameTimeSince(TimeStartedShooting) / ShootDuration);

		CurrentShootLocation = Serpent.ActorTransform.TransformPositionNoScale(Math::Lerp(StartShootLocation, EndTargetLocation, Alpha));
		//Debug::DrawDebugSphere(Serpent.ActorTransform.TransformPositionNoScale(StartShootLocation), 500, 12, FLinearColor::Yellow, 10);
		//Debug::DrawDebugSphere(Serpent.ActorTransform.TransformPositionNoScale(EndTargetLocation), 500, 12, FLinearColor::LucBlue, 10);
		ShootRotation = FRotator::MakeFromX(CurrentShootLocation - StartLocation);
		FVector ShootDirection = ShootRotation.ForwardVector;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		TraceSettings.UseBoxShape(200, 2000, 2000, ShootRotation.Quaternion());
		TraceSettings.IgnoreActor(Serpent);

		//FHazeTraceDebugSettings DebugSettings;
		//DebugSettings.Thickness = 20;
		//TraceSettings.DebugDraw(DebugSettings);

		FVector EndLocation = StartLocation + ShootDirection * BreathDistance;
		FVector ImpactPoint = EndLocation;

		bool bImpactFound = false;

		float ClosestHitTime = MAX_flt;
		for (FHitResult Hit : TraceSettings.QueryTraceMulti(StartLocation, EndLocation))
		{
			//check if we have hit a solid collision and cut off beam there
			if (Hit.Actor != Game::Mio && Hit.Actor != Game::Zoe)
			{
				if (Hit.Time < ClosestHitTime)
				{
					ClosestHitTime = Hit.Time;
					ImpactPoint = Hit.Location;
				}
				bImpactFound = true;
			}

			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if (Player != nullptr)
			{
				Player.DealBatchedDamageOverTime(1.5 * DeltaTime, FPlayerDeathDamageParams(ShootDirection));
			}
		}

		if (bImpactFound)
		{
			if (Serpent.bUseCrystalBreathAnimsInWaterfall)
				USerpentHeadEffectHandler::Trigger_OnBreathHitWaterfall(Serpent, FSerpentHeadCrystalBreathParams(StartLocation, ImpactPoint, ShootDirection.ToOrientationQuat(), ImpactPoint));
			else
				USerpentHeadEffectHandler::Trigger_OnBreathHitRock(Serpent, FSerpentHeadCrystalBreathParams(StartLocation, ImpactPoint, ShootDirection.ToOrientationQuat(), ImpactPoint));
		}

		// if (PlayerTarget.IsPlayerDead())
		// 	PlayerTarget = PlayerTarget.OtherPlayer;

		USerpentHeadEffectHandler::Trigger_UpdateCrystalBreath(Serpent, FSerpentHeadCrystalBreathParams(StartLocation, EndLocation, ShootDirection.ToOrientationQuat(), ImpactPoint));
	}
};