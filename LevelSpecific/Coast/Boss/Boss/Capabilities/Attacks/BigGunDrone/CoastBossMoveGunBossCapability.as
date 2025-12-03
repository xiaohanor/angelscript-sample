class UCoastBossMoveGunBossCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	ACoastBoss CoastBoss;
	ACoastBoss2DPlane ConstrainPlane;
	FHazeAcceleratedFloat AccCoastBossSinusOffset;

	FHazeAcceleratedVector2D AccCoastBossPingPongOffset;
	FVector2D PingPongVelocity(-1.0, 1.0);

	ECoastBossMovementMode LastMovementMode;
	float WaveTimer = 0.0;
	FHazeAcceleratedFloat AccCoastBossWaveOffsetY;
	float CrossMoveTimer = 0.0;
	FHazeAcceleratedFloat AccCoastBossCrossOffsetY;

	FHazeAcceleratedFloat AccCoastBossRaincloudOffsetY;
	FHazeAcceleratedFloat AccCoastBossRaincloudOffsetX;
	float CloudTimer = 0.0;

	FHazeAcceleratedFloat AccCoastBossDrillbazzOffset;
	float DrillbazzTimer = 0.0;

	FHazeAcceleratedFloat AccPitchRotationSpeed;
	float BossPitchRotationAngle = 0.0;
	FHazeAcceleratedFloat AccRollRotationSpeed;
	float BossRollRotationAngle = 0.0;

	FHazeAcceleratedVector2D AccCoastBossLocation;

	FHazeAcceleratedRotator AccGunRot;
	float LastGunRotAngle = 0.0;
	float GunRotTargetTimer = 0.0;
	float LastGunRotStart = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoastBoss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CoastBoss.State == ECoastBossState::Idle)
			return false;
		if (CoastBossDevToggles::UseManyDrones.IsEnabled())
			return false;
		if(CoastBoss.bDead)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CoastBossDevToggles::UseManyDrones.IsEnabled())
			return true;
		if(CoastBoss.bDead)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (!TryCacheThings())
			return;

		CoastBoss.ManualRelativeLocation = ConstrainPlane.GetLocationOnPlane(CoastBoss.ActorLocation);
		CoastBoss.OGBossLocation = CoastBoss.ManualRelativeLocation;
		AccCoastBossLocation.SnapTo(CoastBoss.ManualRelativeLocation);
		CoastBoss.RemoveActorVisualsBlock(CoastBoss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CoastBoss.ManualRelativeLocation = AccCoastBossLocation.Value;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		UpdateDronesBossRotation(DeltaTime);
		UpdateBossMove(DeltaTime);

		UpdateBigGunBoss(DeltaTime);
		RotateGuns(DeltaTime);
	}

	void UpdateBossMove(float DeltaSeconds)
	{
		ECoastBossMovementMode MovementMode = CoastBoss.GunBossMovementMode;
		if (LastMovementMode != MovementMode)
		{
			CrossMoveTimer = 0.0;
			WaveTimer = 0.0;
			LastMovementMode = MovementMode;
		}

		if (MovementMode == ECoastBossMovementMode::LerpIn)
		{
			if (CoastBoss.LerpInDuration > KINDA_SMALL_NUMBER)
			{
				CoastBoss.AccCoastBossStartOffset.AccelerateTo(0.0, CoastBoss.LerpInDuration * 0.9, DeltaSeconds);
			}
		}
		else
			CoastBoss.AccCoastBossStartOffset.AccelerateTo(0.0, 1.0, DeltaSeconds);

		if (MovementMode == ECoastBossMovementMode::LerpIn || MovementMode == ECoastBossMovementMode::IdleBobbing)
		{
			const float UpDownLoopSeconds = 2.4;
			float SinAlpha = Math::Wrap(ActiveDuration, 0.0, UpDownLoopSeconds) / UpDownLoopSeconds;
			AccCoastBossSinusOffset.AccelerateTo(Math::Sin(PI * 2.0 * SinAlpha) * 100.0, 0.5, DeltaSeconds);
		}
		else
			AccCoastBossSinusOffset.AccelerateTo(0.0, 1.0, DeltaSeconds);

		WaveTimer += DeltaSeconds;
		float WaveTarget = 0.0;
		if (MovementMode == ECoastBossMovementMode::WaveDown)
		{
			float WaveAlpha = Math::Clamp(WaveTimer / CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_Duration, 0.0, 1.0);
		 	WaveTarget = CoastBossWaveDownCurve.GetFloatValue(WaveAlpha) * ConstrainPlane.PlaneExtents.Y * CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_MoveDownPercent;
		}
		else if (MovementMode == ECoastBossMovementMode::WaveUp)
		{
			float WaveAlpha = Math::Clamp(WaveTimer / CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_Interval, 0.0, 1.0);
		 	WaveTarget = CoastBossWaveUpCurve.GetFloatValue(WaveAlpha) * ConstrainPlane.PlaneExtents.Y * CoastBossConstants::BigDroneBoss::Phase1_WaveAttack_MoveUpPercent;
		}
		AccCoastBossWaveOffsetY.AccelerateTo(WaveTarget, 0.1, DeltaSeconds);

		CrossMoveTimer += DeltaSeconds;
		float CrossTarget = 0.0;
		if (MovementMode == ECoastBossMovementMode::CrossDownUp)
		{
			float CrossAlpha = Math::Clamp(CrossMoveTimer / CoastBossConstants::BigDroneBoss::Phase2_CrossMoveDownUp_Duration, 0.0, 1.0);
		 	CrossTarget = CoastBossCrossDownUpCurve.GetFloatValue(CrossAlpha) * ConstrainPlane.PlaneExtents.Y * CoastBossConstants::BigDroneBoss::Phase2_CrossMoveDownUp_Percent;
		}
		else if (MovementMode == ECoastBossMovementMode::CrossUpDown)
		{
			float CrossAlpha = Math::Clamp(CrossMoveTimer / CoastBossConstants::BigDroneBoss::Phase2_CrossMoveUpDown_Duration, 0.0, 1.0);
		 	CrossTarget = CoastBossCrossUpDownCurve.GetFloatValue(CrossAlpha) * ConstrainPlane.PlaneExtents.Y * CoastBossConstants::BigDroneBoss::Phase2_CrossMoveUpDown_Percent;
		}
		AccCoastBossCrossOffsetY.AccelerateTo(CrossTarget, 0.1, DeltaSeconds);

		if (MovementMode == ECoastBossMovementMode::CloudRainSinus)
		{
			float CloudLoop = CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudMoveScreenDuration * 2.0 * CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudRainLoops;
			CloudTimer += DeltaSeconds;
			if (CloudTimer >= CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudDuration)
			{
				//CoastBoss.AttackActionQueue.Empty();
				CoastBoss.bExitCloud = true;
			}
			CloudTimer = Math::Clamp(CloudTimer, 0.0, CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudDuration);

			const float TargetX = -ConstrainPlane.PlaneExtents.X * 2.0 + 1300.0;
			if (CloudTimer < CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudUpDuration)
			{
				AccCoastBossRaincloudOffsetY.AccelerateTo(ConstrainPlane.PlaneExtents.Y * 0.9, CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudUpDuration, DeltaSeconds);
			}
			else if (CloudTimer - CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudUpDuration < CloudLoop)
			{
				float CloudMoveTimer = CloudTimer - CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudUpDuration;

				float CloudyLoopy = Math::Wrap(CloudMoveTimer, 0.0, CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudMoveScreenDuration * 2.0);
				float NewX = 0.0;
				if (CloudyLoopy < CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudMoveScreenDuration)
				{
					NewX = TargetX * (CloudyLoopy / CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudMoveScreenDuration);
				}
				else if (CloudyLoopy > CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudMoveScreenDuration)
				{
					float Alpha = 1.0 - ((CloudyLoopy - CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudMoveScreenDuration) / CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudMoveScreenDuration);
					NewX = TargetX * Alpha;
				}
				AccCoastBossRaincloudOffsetX.SnapTo(NewX);
			}
			else
			{
				CoastBoss.bRainRecover = true;
				AccCoastBossRaincloudOffsetY.AccelerateTo(0.0, CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudDownDuration, DeltaSeconds);
			}
		}
		else
		{
			CoastBoss.bRainRecover = false;
			AccCoastBossRaincloudOffsetY.AccelerateTo(0, 1.0, DeltaSeconds);
			AccCoastBossRaincloudOffsetX.AccelerateTo(0, 3.0, DeltaSeconds);
			CloudTimer = 0.0;
		}

		if (MovementMode == ECoastBossMovementMode::Drillbazz)
		{
			DrillbazzTimer += DeltaSeconds;

			CoastBoss.ChargeAlpha = 0.0;
			if (DrillbazzTimer < CoastBossConstants::BigDroneBoss::Phase4_ChargetAttack_AnticipationDuration)
				AccCoastBossDrillbazzOffset.AccelerateTo(800.0, CoastBossConstants::BigDroneBoss::Phase4_ChargetAttack_AnticipationDuration, DeltaSeconds);
			else //if (DrillbazzTimer < CoastBossConstants::BigDroneBoss::Phase4_ChargetAttack_ChargeDuration)
			{
				float ChargeTimer = DrillbazzTimer - CoastBossConstants::BigDroneBoss::Phase4_ChargetAttack_AnticipationDuration;
				float ChargeAlpha = Math::Clamp(ChargeTimer / CoastBossConstants::BigDroneBoss::Phase4_ChargetAttack_ChargeDuration, 0.0, 1.0);
				CoastBoss.ChargeAlpha = ChargeAlpha;
				float XChargeValue = -ConstrainPlane.PlaneExtents.X * 1.8 * CoastBossChargeCurve.GetFloatValue(ChargeAlpha);
				AccCoastBossDrillbazzOffset.SnapTo(XChargeValue);
			}
		}
		else
		{
			AccCoastBossDrillbazzOffset.AccelerateTo(0.0, 0.5, DeltaSeconds);
			DrillbazzTimer = 0.0;
		}

		if (MovementMode == ECoastBossMovementMode::PingPong)
		{
			FVector2D NewPingPongLocation = AccCoastBossPingPongOffset.Value;
			const float Speedy = Math::Lerp(CoastBossConstants::BigDroneBoss::Phase6_BossSpeedMin, CoastBossConstants::BigDroneBoss::Phase6_BossSpeedMax, CoastBossPingPongSpeedCurve.GetFloatValue(CoastBoss.GetPingPongAlpha()));
			NewPingPongLocation += PingPongVelocity * Speedy * DeltaSeconds;
			float Added = 50.0;
			float MinX = 0.0 - ConstrainPlane.PlaneExtents.X - CoastBoss.OGBossLocation.X - Added * 2.0;
			float MaxX = 0.0 + ConstrainPlane.PlaneExtents.X + Added - CoastBoss.OGBossLocation.X;
			if (NewPingPongLocation.X < MinX || NewPingPongLocation.X > MaxX)
			{
				PingPongVelocity.X *= -1.0;
				NewPingPongLocation.X = Math::Clamp(NewPingPongLocation.X, MinX, MaxX);
				CoastBoss.PingPongWaveDirection = FVector2D(Math::Sign(PingPongVelocity.X), 0.0);
				//CoastBoss.AttackActionQueue.Empty();
			}
			if (NewPingPongLocation.Y < -ConstrainPlane.PlaneExtents.Y || NewPingPongLocation.Y > ConstrainPlane.PlaneExtents.Y)
			{
				PingPongVelocity.Y *= -1.0;
				NewPingPongLocation.Y = Math::Clamp(NewPingPongLocation.Y, -ConstrainPlane.PlaneExtents.Y, ConstrainPlane.PlaneExtents.Y);
				CoastBoss.PingPongWaveDirection = FVector2D(0.0, Math::Sign(PingPongVelocity.Y));
				//CoastBoss.AttackActionQueue.Empty();
			}
			
			AccCoastBossPingPongOffset.SnapTo(NewPingPongLocation);
		}
		else
		{
			AccCoastBossPingPongOffset.AccelerateTo(FVector2D(), 1.0, DeltaSeconds);
		}

		CoastBoss.ManualRelativeLocation.Y = CoastBoss.OGBossLocation.Y + CoastBoss.AccCoastBossStartOffset.Value + AccCoastBossSinusOffset.Value + AccCoastBossWaveOffsetY.Value + AccCoastBossRaincloudOffsetY.Value + AccCoastBossPingPongOffset.Value.Y + AccCoastBossCrossOffsetY.Value;
		CoastBoss.ManualRelativeLocation.X = CoastBoss.OGBossLocation.X + AccCoastBossDrillbazzOffset.Value + AccCoastBossRaincloudOffsetX.Value + AccCoastBossPingPongOffset.Value.X;
	}

	void UpdateDronesBossRotation(float DeltaSeconds)
	{
		float PitchSpeed = 0.0;
		float RollSpeed = 0.0;
		CoastBoss.GetRotateSpeed(PitchSpeed, RollSpeed);
		
		AccPitchRotationSpeed.AccelerateTo(PitchSpeed, 1.0, DeltaSeconds);
		BossPitchRotationAngle += PitchSpeed * DeltaSeconds;
		if (Math::IsNearlyEqual(PitchSpeed, 0.0, KINDA_SMALL_NUMBER))
		{
			if (!Math::IsNearlyEqual(BossPitchRotationAngle, 0.0, 0.1))
			{
				bool RotateClockwise = BossPitchRotationAngle > 180;
				float Multiplier = RotateClockwise ? 180 : -180;
				BossPitchRotationAngle += Multiplier * DeltaSeconds;
				bool bStopRotate = (!RotateClockwise && BossPitchRotationAngle < 0.0) || (RotateClockwise && BossPitchRotationAngle > 360.0);
				if (bStopRotate)
					BossPitchRotationAngle = 0.0;
			}
		}
		BossPitchRotationAngle = Math::Wrap(BossPitchRotationAngle, 0.0, 360.0);
		CoastBoss.BossPitchRadians = Math::DegreesToRadians(BossPitchRotationAngle);

		AccRollRotationSpeed.AccelerateTo(RollSpeed, 1.0, DeltaSeconds);
		if (!Math::IsNearlyEqual(RollSpeed, 0.0, KINDA_SMALL_NUMBER))
			CoastBoss.DrillSpeedAlpha = Math::Clamp(AccRollRotationSpeed.Value / RollSpeed, 0.0, 1.0);
		else
			CoastBoss.DrillSpeedAlpha = 0.0;

		BossRollRotationAngle += RollSpeed * DeltaSeconds;
		if (RollSpeed < KINDA_SMALL_NUMBER)
		{
			if (!Math::IsNearlyEqual(BossRollRotationAngle, 0.0, 0.1))
			{
				bool RotateClockwise = BossRollRotationAngle > 180;
				float Multiplier = RotateClockwise ? 180 : -180;
				BossRollRotationAngle += Multiplier * DeltaSeconds;
				bool bStopRotate = (!RotateClockwise && BossRollRotationAngle < 0.0) || (RotateClockwise && BossRollRotationAngle > 360.0);
				if (bStopRotate)
					BossRollRotationAngle = 0.0;
			}
		}
		BossRollRotationAngle = Math::Wrap(BossRollRotationAngle, 0.0, 360.0);
		CoastBoss.BossRollRadians = Math::DegreesToRadians(BossRollRotationAngle);
	}

	void UpdateBigGunBoss(float DeltaSeconds)
	{
		AccCoastBossLocation.AccelerateTo(CoastBoss.ManualRelativeLocation, 1.0, DeltaSeconds);
		FVector2D ActualRelativeLocation = AccCoastBossLocation.Value;
		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(ActualRelativeLocation);
		CoastBoss.SetActorLocationAndRotation(WorldLocation, ConstrainPlane.ActorRotation);
		// FRotator BossRotation = FRotator::MakeFromXZ(ConstrainPlane.ActorForwardVector, ConstrainPlane.ActorUpVector);
	}

	void RotateGuns(float DeltaSeconds)
	{
		FCoastBossGunRotateData RotateData = CoastBoss.GetCurrentRotateData();
		if (!Math::IsNearlyEqual(LastGunRotAngle, RotateData.TargetShootAngle))
		{
			GunRotTargetTimer = 0.0;
			LastGunRotStart = AccGunRot.Value.Pitch;
		}
		GunRotTargetTimer += DeltaSeconds;
		LastGunRotAngle = RotateData.TargetShootAngle;

		bool bPingPongRotation = CoastBoss.GetPhase() == ECoastBossPhase::Phase6;
		if (bPingPongRotation)
		{
			FVector2D TowardsCenter = -CoastBoss.ManualRelativeLocation;
			FRotator GunRelativeRot;
			float Pitch = Math::RadiansToDegrees(Math::Atan2(TowardsCenter.X, TowardsCenter.Y) + PI * 0.5);
			GunRelativeRot.Pitch = Pitch;
			AccGunRot.AccelerateTo(GunRelativeRot, 0.1, DeltaSeconds);
		}
		else if (RotateData.bUseBossPitchRot)
		{
			FRotator GunRelativeRot;
			GunRelativeRot.Pitch = Math::RadiansToDegrees(CoastBoss.BossPitchRadians);
			AccGunRot.SpringTo(GunRelativeRot, 100.0, 0.9, DeltaSeconds);
		}
		else if (RotateData.OverrideDuration > KINDA_SMALL_NUMBER)
		{
			float Alpha = Math::Clamp(GunRotTargetTimer / RotateData.OverrideDuration, 0.0, 1.0);
			float NewPitch = Math::Lerp(LastGunRotStart, RotateData.TargetShootAngle, Alpha);
			FRotator GunRelativeRot;
			GunRelativeRot.Pitch = NewPitch;
			AccGunRot.AccelerateTo(GunRelativeRot, 0.1, DeltaSeconds);
		}
		else
		{
			FRotator GunRelativeRot;
			GunRelativeRot.Pitch = RotateData.TargetShootAngle;
			AccGunRot.ThrustTo(GunRelativeRot, 360.0, DeltaSeconds);
		}

		FRotator WorldRotation = FTransform(FRotator::MakeFromZX(FVector::UpVector, CoastBoss.BossMeshComp.ForwardVector)).TransformRotation(AccGunRot.Value);
		FRotator RelativeRotation = CoastBoss.BossMeshComp.WorldTransform.InverseTransformRotation(WorldRotation);
		CoastBoss.AnimData.SetTurretRelativeRotation(RelativeRotation, ECoastBossBoneName::LeftTurret);
		CoastBoss.AnimData.SetTurretRelativeRotation(RelativeRotation, ECoastBossBoneName::RightTurret);

		ApplyRecoilForGun(false);
		ApplyRecoilForGun(true);

		if (CoastBossDevToggles::Draw::DrawDebugBoss.IsEnabled())
		{
			FLinearColor Coloring = ColorDebug::Magenta;
			Debug::DrawDebugSphere(CoastBoss.GetMuzzleBulletLocation(true, false), 30, 12, Coloring, 10.0, 0.0, true);
			Debug::DrawDebugSphere(CoastBoss.GetMuzzleBulletLocation(false, false), 30, 12, Coloring, 10.0, 0.0, true);
			
			Coloring = ColorDebug::Carrot;
			Debug::DrawDebugSphere(CoastBoss.GetMuzzleFlashLocation(true, false), 30, 12, Coloring, 10.0, 0.0, true);
			Debug::DrawDebugSphere(CoastBoss.GetMuzzleFlashLocation(false, false), 30, 12, Coloring, 10.0, 0.0, true);
		}
	}

	void ApplyRecoilForGun(bool bRight)
	{
		float RecoilTimer = Time::GameTimeSeconds - (bRight ? CoastBoss.RightGunShootVisualsStartTimeStamp : CoastBoss.LeftGunShootVisualsStartTimeStamp);
		float RecoilAlpha = Math::Clamp(RecoilTimer / CoastBossConstants::BigDroneBoss::GunRecoilDuration, 0.0, 1.0);
		float RecoilOffset = CoastBossRecoilCurve.GetFloatValue(RecoilAlpha) * CoastBossConstants::BigDroneBoss::GunRecoilOffset;

		CoastBoss.AnimData.SetRecoilOffset(-RecoilOffset, bRight ? ECoastBossBoneName::RightTurret : ECoastBossBoneName::LeftTurret);
		if(bRight)
			CoastBoss.AnimData.SetRecoilOffset(-RecoilOffset, CoastBoss.bRightGunShotUp ? ECoastBossBoneName::RightUpBarrel : ECoastBossBoneName::RightDownBarrel);
		else
			CoastBoss.AnimData.SetRecoilOffset(-RecoilOffset, CoastBoss.bLeftGunShotUp ? ECoastBossBoneName::LeftUpBarrel : ECoastBossBoneName::LeftDownBarrel);
	}

	bool TryCacheThings()
	{
		if (ConstrainPlane == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
				ConstrainPlane = Refs.Single.CoastBossPlane2D;
		}
		return ConstrainPlane != nullptr;
	}
};
