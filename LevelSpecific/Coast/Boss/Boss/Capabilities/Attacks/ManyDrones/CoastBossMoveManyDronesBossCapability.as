class UCoastBossMoveManyDronesBossCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	ACoastBoss CoastBoss;
	ACoastBoss2DPlane ConstrainPlane;
	FHazeAcceleratedFloat AccCoastBossSinusOffset;

	FHazeAcceleratedVector2D AccCoastBossPingPongOffset;
	FVector2D PingPongVelocity(-1.0, 1.0);

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
		if (!CoastBossDevToggles::UseManyDrones.IsEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CoastBossDevToggles::UseManyDrones.IsEnabled())
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		UpdateDronesBossRotation(DeltaTime);
		UpdateBossMove(DeltaTime);
	}

	void UpdateBossMove(float DeltaSeconds)
	{
		ECoastBossMovementMode MovementMode = CoastBoss.GetMovementMode();
		if (MovementMode == ECoastBossMovementMode::IdleBobbing)
		{
			const float UpDownLoopSeconds = 2.4;
			float SinAlpha = Math::Wrap(ActiveDuration, 0.0, UpDownLoopSeconds) / UpDownLoopSeconds;
			AccCoastBossSinusOffset.SnapTo(Math::Sin(PI * 2.0 * SinAlpha) * 100.0);
		}
		else
			AccCoastBossSinusOffset.AccelerateTo(0.0, 1.0, DeltaSeconds);

		if (MovementMode == ECoastBossMovementMode::CloudRainSinus)
		{
			float CloudLoop = CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudMoveScreenDuration * 2.0 * CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudRainLoops;
			CloudTimer += DeltaSeconds;
			if (CloudTimer >= CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudDuration)
			{
				CoastBoss.AttackActionQueue.Empty();
				CoastBoss.bExitCloud = true;
			}
			CloudTimer = Math::Clamp(CloudTimer, 0.0, CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudDuration);

			const float TargetX = -ConstrainPlane.PlaneExtents.X * 1.6;
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
				AccCoastBossRaincloudOffsetY.AccelerateTo(0.0, CoastBossConstants::ManyDronesBoss::Phase16Drones_Weather_CloudDownDuration, DeltaSeconds);
			}
		}
		else
		{
			AccCoastBossRaincloudOffsetY.AccelerateTo(0, 1.0, DeltaSeconds);
			AccCoastBossRaincloudOffsetX.AccelerateTo(0, 3.0, DeltaSeconds);
			CloudTimer = 0.0;
		}

		if (MovementMode == ECoastBossMovementMode::Drillbazz)
		{
			DrillbazzTimer += DeltaSeconds;

			if (DrillbazzTimer < CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzWindUpDuration)
				AccCoastBossDrillbazzOffset.AccelerateTo(800.0, 2.0, DeltaSeconds);
			else if (DrillbazzTimer < CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzAttackDuration)
				AccCoastBossDrillbazzOffset.ThrustTo(-ConstrainPlane.PlaneExtents.X * 1.8, 10000.0, DeltaSeconds);
			else
				AccCoastBossDrillbazzOffset.AccelerateTo(0.0, CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzRetreatDuration, DeltaSeconds);
		}
		else
		{
			AccCoastBossDrillbazzOffset.AccelerateTo(0.0, 2.0, DeltaSeconds);
			DrillbazzTimer = 0.0;
		}

		if (MovementMode == ECoastBossMovementMode::PingPong)
		{
			FVector2D NewPingPongLocation = AccCoastBossPingPongOffset.Value;
			const float Speedy = CoastBossConstants::ManyDronesBoss::Phase4Drones_SpeedBase + CoastBossConstants::ManyDronesBoss::Phase4Drones_SpeedPerDrone * CoastBoss.AliveDrones;
			NewPingPongLocation += PingPongVelocity * Speedy * DeltaSeconds;
			float Added = 50.0;
			float MinX = 0.0 - ConstrainPlane.PlaneExtents.X - CoastBoss.OGBossLocation.X - Added * 2.0;
			float MaxX = 0.0 + ConstrainPlane.PlaneExtents.X + Added - CoastBoss.OGBossLocation.X;
			if (NewPingPongLocation.X < MinX || NewPingPongLocation.X > MaxX)
			{
				PingPongVelocity.X *= -1.0;
				NewPingPongLocation.X = Math::Clamp(NewPingPongLocation.X, MinX, MaxX);
				CoastBoss.PingPongWaveDirection = FVector2D(Math::Sign(PingPongVelocity.X), 0.0);
				CoastBoss.AttackActionQueue.Empty();
			}
			if (NewPingPongLocation.Y < -ConstrainPlane.PlaneExtents.Y || NewPingPongLocation.Y > ConstrainPlane.PlaneExtents.Y)
			{
				PingPongVelocity.Y *= -1.0;
				NewPingPongLocation.Y = Math::Clamp(NewPingPongLocation.Y, -ConstrainPlane.PlaneExtents.Y, ConstrainPlane.PlaneExtents.Y);
				CoastBoss.PingPongWaveDirection = FVector2D(0.0, Math::Sign(PingPongVelocity.Y));
				CoastBoss.AttackActionQueue.Empty();
			}
			
			// Debug::DrawDebugString(CoastBoss.ActorLocation, "LocX " + NewPingPongLocation.X);
			AccCoastBossPingPongOffset.SnapTo(NewPingPongLocation);
		}
		else
		{
			AccCoastBossPingPongOffset.AccelerateTo(FVector2D(), 1.0, DeltaSeconds);
		}

		CoastBoss.ManualRelativeLocation.Y = CoastBoss.OGBossLocation.Y + AccCoastBossSinusOffset.Value + AccCoastBossRaincloudOffsetY.Value + AccCoastBossPingPongOffset.Value.Y;
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
