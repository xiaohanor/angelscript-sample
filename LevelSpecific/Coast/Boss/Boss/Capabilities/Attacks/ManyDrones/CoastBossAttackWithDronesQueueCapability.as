class UCoastBossAttackWithDronesQueueCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;
	
	ACoastBoss CoastBoss;
	ACoastBossActorReferences References;
	int StarShots = 0;
	UCoastBossDroneComponent LastMillShooter;
	int MillShots = 0;

	int RainShots = 0;
	float WaveAngle = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoastBoss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (CoastBoss.State != ECoastBossState::Shooting)
			return false;
		if (!CoastBoss.AttackActionQueue.IsEmpty())
			return false;
		if (CoastBoss.bDead)
			return false;
		if (!CoastBossDevToggles::UseManyDrones.IsEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CoastBoss.AttackActionQueue.IsEmpty())
			return true;
		return false;
	}

	bool TryCacheThings()
	{
		if (References == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
				References = Refs.Single;
		}
		return References != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		switch (CoastBoss.GetPhase())
		{
			case ECoastBossPhase::LerpIn:
			{
				break;
			}
			case ECoastBossPhase::Phase1:
			{
				StarSequence();
				break;
			}
			case ECoastBossPhase::Phase2:
			{
				CrossSequence();
				break;
			}
			case ECoastBossPhase::Phase3:
			{
				WeatherSequence();
				break;
			}
			case ECoastBossPhase::Phase4:
			{
				DrillbazzSequence();
				break;
			}
			case ECoastBossPhase::Phase5:
			{
				BananaSequence();
				CoastBoss.AttackActionQueue.Idle(CoastBossConstants::ManyDronesBoss::Phase8Drones_AttackCooldown);
				break;
			}
			case ECoastBossPhase::Phase6:
			{
				PingPongSequence();
				break;
			}
		}
	}

	void StarSequence()
	{
		ShootAllBall();
		CoastBoss.AttackActionQueue.Idle(CoastBossConstants::ManyDronesBoss::Phase24Drones_BulletCooldown);
	}

	void PingPongSequence()
	{
		if (CoastBoss.PingPongWaveDirection.Size() > KINDA_SMALL_NUMBER)
		{
			ShootPingPongWave(CoastBoss.PingPongWaveDirection);
			CoastBoss.PingPongWaveDirection = FVector2D::ZeroVector;
		}
		else
		{
			ShootTrailBall();
			if (CoastBoss.AliveDrones <= 2)
				CoastBoss.AttackActionQueue.Idle(CoastBossConstants::ManyDronesBoss::Phase4Drones_TrailAttackInterval * 2.0);
			else
				CoastBoss.AttackActionQueue.Idle(CoastBossConstants::ManyDronesBoss::Phase4Drones_TrailAttackInterval);
		}
	}

	void BananaSequence()
	{
		const float WaveCooldown = CoastBossConstants::ManyDronesBoss::Phase8Drones_AttackInterval;
		bool bClockwise = Math::RandBool();
		FVector2D MinMaxAngle = CoastBossConstants::ManyDronesBoss::Phase8Drones_Attack_ClockwiseMinMaxAngles;
		if (!bClockwise)
			MinMaxAngle = CoastBossConstants::ManyDronesBoss::Phase8Drones_Attack_CClockwiseMinMaxAngles;
		WaveAngle = Math::RandRange(MinMaxAngle.X, MinMaxAngle.Y);
		ShootWave(bClockwise);
		CoastBoss.AttackActionQueue.Idle(WaveCooldown);
		ShootWave(bClockwise);
		CoastBoss.AttackActionQueue.Idle(WaveCooldown);
		ShootWave(bClockwise);
	}

	void CrossSequence()
	{
		MillShots++;
		if (MillShots > 1)
				MillShots = -1;
			ShootFrontMill(FVector2D(-CoastBossConstants::ManyDronesBoss::Phase20Drones_Cross_VelocityHorizontal, CoastBossConstants::ManyDronesBoss::Phase20Drones_Cross_VelocityMaxVertical * MillShots));
		CoastBoss.AttackActionQueue.Idle(CoastBossConstants::ManyDronesBoss::Phase20Drones_CrossCooldown);
	}

	void WeatherSequence()
	{
		if (CoastBoss.CurrentFormation == ECoastBossFormation::State16_Sun)
		{
			ShootFrontMine();
			CoastBoss.AttackActionQueue.Idle(0.4);
			ShootFrontMine();
			CoastBoss.AttackActionQueue.Idle(2.0);
			for (int iSunray = 0; iSunray < 8; iSunray++)
			{
				ShootFrontBall();
				CoastBoss.AttackActionQueue.Idle(0.2);
			}
			CoastBoss.AttackActionQueue.Idle(3.0);
			ChangeFormation(ECoastBossFormation::State16_Raincloud);
			CoastBoss.AttackActionQueue.Idle(1.0);
		}
		if (CoastBoss.CurrentFormation == ECoastBossFormation::State16_Raincloud)
		{
			if (CoastBoss.bExitCloud)
			{
				RainShots = 0;
				ChangeFormation(ECoastBossFormation::State16_Sun);
				CoastBoss.AttackActionQueue.Idle(1.0);
				CoastBoss.bExitCloud = false;
					return;
			}

			++RainShots;
			ShootRainBall();
			if (RainShots % 3 == 0)
				CoastBoss.AttackActionQueue.Idle(0.35);
			else
				CoastBoss.AttackActionQueue.Idle(0.25);

		}
	}

	void DrillbazzSequence()
	{
		if (CoastBoss.CurrentFormation == ECoastBossFormation::State12_Drillbazz)
		{
			CoastBoss.AttackActionQueue.Idle(CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzWindUpDuration);
			CoastBoss.AttackActionQueue.Idle(CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzAttackDuration);
			ChangeFormation(ECoastBossFormation::State12_Sinus);
			CoastBoss.AttackActionQueue.Idle(CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzPauseDuration);
		}
		else
		{
			float ShootyDuration = CoastBossConstants::ManyDronesBoss::Phase12Drones_VolleyDuration;
			float BulletWaves = 3.0;
			float Fraction = ShootyDuration / BulletWaves;
			for (float iWave = 0.0; iWave < ShootyDuration - 0.01; iWave += Fraction)
			{
				ShootFrontBall();
				ShootFrontBall();
				ShootFrontBall();
				ShootFrontBall();
				ShootFrontBall();
				ShootFrontBall();
				CoastBoss.AttackActionQueue.Idle(Fraction);
			}
			CoastBoss.AttackActionQueue.Idle(ShootyDuration);
			ChangeFormation(ECoastBossFormation::State12_Drillbazz);
		}
	}

	void FrontShootSequence()
	{
		CoastBoss.AttackActionQueue.Idle(0.2);
		ShootFrontBall();
		CoastBoss.AttackActionQueue.Idle(0.2);
		ShootFrontBall();
		CoastBoss.AttackActionQueue.Idle(0.2);
		ShootFrontBall();
		CoastBoss.AttackActionQueue.Idle(0.7);
	}

	void ShootFrontBall()
	{
		const float MinSidewaysVelocity = 1000.0;
		const float MaxSidewaysVelocity = MinSidewaysVelocity + 700.0;
		const float HeightSpan = 600.0;
		FCoastBossPlayerBulletData BulletData;
		BulletData.Velocity = FVector2D(-Math::RandRange(MinSidewaysVelocity, MaxSidewaysVelocity), Math::RandRange(-HeightSpan, HeightSpan));
		FVector2D StartLocation = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.ActorLocation);

		for (int iDrone = 0; iDrone < CoastBoss.DroneActors.Num(); ++iDrone)
		{
			if (CoastBoss.DroneActors[iDrone].bDead)
				continue;

			// find forwardmost drone
			FVector2D DroneLocaton = CoastBoss.DroneActors[iDrone].ActualRelativeLocation;
			if (DroneLocaton.X < StartLocation.X)
				StartLocation = DroneLocaton;
		}
			
		BulletData.Location = StartLocation;

		FCoastBossShootBallActionParams ShootParams;
		ShootParams.BulletDatas.Add(BulletData);
		CoastBoss.AttackActionQueue.Capability(UCoastBossShootBallCapability, ShootParams);
	}


	void ShootTrailBall()
	{
		FCoastBossPlayerBulletData BulletData;
		BulletData.Velocity = FVector2D(0.0, -1000.0);
		BulletData.Location = CoastBoss.ManualRelativeLocation;
		FCoastBossShootBallActionParams ShootParams;
		ShootParams.BulletDatas.Add(BulletData);
		CoastBoss.AttackActionQueue.Capability(UCoastBossShootBallCapability, ShootParams);
	}

	void ShootRainBall()
	{
		FCoastBossPlayerBulletData BulletData;
		BulletData.Velocity = FVector2D(0.0, -700.0);
		// FVector2D StartLocation = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.ActorLocation);

		float MinX = 100000.0;
		float MaxX = -100000.0;
		float MinY = 100000.0;
		for (int iDrone = 0; iDrone < CoastBoss.DroneActors.Num(); ++iDrone)
		{
			if (CoastBoss.DroneActors[iDrone].bDead)
				continue;

			// find downwards drone
			FVector2D DroneLocaton = CoastBoss.DroneActors[iDrone].ActualRelativeLocation;
			if (DroneLocaton.Y < MinY)
				MinY = DroneLocaton.Y;
			if (DroneLocaton.X < MinX)
				MinX = DroneLocaton.X;
			if (DroneLocaton.X > MaxX)
				MaxX = DroneLocaton.X;
		}
		
		int Placement = 1 - (RainShots % 3);
		float Diff = (MaxX - MinX) * 0.5;
		float UsedX = MinX + Diff * Placement;
		
		// BulletData.Location = FVector2D(UsedX, MinY);

		BulletData.Location = FVector2D(Math::RandRange(MinX, MaxX), MinY);


		FCoastBossShootBallActionParams ShootParams;
		ShootParams.BulletDatas.Add(BulletData);
		CoastBoss.AttackActionQueue.Capability(UCoastBossShootBallCapability, ShootParams);
	}
	
	void ShootFrontMill(FVector2D Velocity)
	{
		FCoastBossShootMillActionParams ShootParams;
		ShootParams.BulletData.Velocity = Velocity;
		FVector2D StartLocation = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.ActorLocation);

		// UCoastBossDroneComponent Shooter;
		// for (int iDrone = 0; iDrone < CoastBoss.Drones.Num(); ++iDrone)
		// {
		// 	if (CoastBoss.Drones[iDrone].bPrototypingDead)
		// 		continue;

		// 	if (!CoastBoss.Drones[iDrone].bIsShootyDrone)
		// 		continue;

		// 	if (LastMillShooter == CoastBoss.Drones[iDrone])
		// 		continue;
		// 	// find forwardmost & centralmost drone
		// 	FVector2D DroneLocaton = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.Drones[iDrone].WorldLocation);
		// 	if (DroneLocaton.X < StartLocation.X && DroneLocaton.Y < StartLocation.Y)
		// 	{
		// 		StartLocation = DroneLocaton;
		// 		Shooter = CoastBoss.Drones[iDrone];
		// 	}
		// }
		// LastMillShooter = Shooter;
			
		ShootParams.BulletData.Location = StartLocation;
		CoastBoss.AttackActionQueue.Capability(UCoastBossShootMillCapability, ShootParams);
	}

	void ShootFrontMine()
	{
		FCoastBossShootMineActionParams ShootParams;
		ShootParams.BulletData.Velocity = FVector2D(0.0, 0.0);
		FVector2D StartLocation = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.ActorLocation);

		// for (int iDrone = 0; iDrone < CoastBoss.DroneActors.Num(); ++iDrone)
		// {
		// 	if (CoastBoss.DroneActors[iDrone].bDead)
		// 		continue;

		// 	if (!CoastBoss.DroneActors[iDrone].DroneMesh.bIsShootyDrone)
		// 		continue;

		// 	// find forwardmost & centralmost drone
		// 	FVector2D DroneLocaton = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.DroneActors[iDrone].ActorLocation);
		// 	if (DroneLocaton.X < StartLocation.X && DroneLocaton.Y < StartLocation.Y)
		// 	{
		// 		StartLocation = DroneLocaton;
		// 	}
		// }
			
		ShootParams.BulletData.Location = StartLocation;
		CoastBoss.AttackActionQueue.Capability(UCoastBossShootMineCapability, ShootParams);
	}

	void ShootAllBall()
	{
		FCoastBossShootBallActionParams ShootParams;
		FVector2D BossLocation = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.ActorLocation);
		for (int iDrone = 0; iDrone < CoastBoss.DroneActors.Num(); ++iDrone)
		{
			if (CoastBoss.DroneActors[iDrone].bDead)
				continue;

			if (CoastBoss.DroneActors[iDrone].DroneMesh.bIsShootyDrone)
			{
				FCoastBossPlayerBulletData BulletData;

				FVector2D DroneLocaton = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.DroneActors[iDrone].ActorLocation);
				BulletData.Location = DroneLocaton;
				BulletData.Velocity = (DroneLocaton - BossLocation).GetSafeNormal() * CoastBossConstants::ManyDronesBoss::Phase24Drones_BulletSpeed;
				ShootParams.BulletDatas.Add(BulletData);
			}
		}
		CoastBoss.AttackActionQueue.Capability(UCoastBossShootBallCapability, ShootParams);
	}

	void ShootWave(bool bClockwise)
	{
		FVector2D StartLocation = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.ActorLocation);
		for (int iDrone = 0; iDrone < CoastBoss.DroneActors.Num(); ++iDrone)
		{
			if (CoastBoss.DroneActors[iDrone].bDead)
				continue;

			// find forwardmost drone
			FVector2D DroneLocaton = References.CoastBossPlane2D.GetLocationOnPlane(CoastBoss.DroneActors[iDrone].ActorLocation);
			if (DroneLocaton.X < StartLocation.X)
				StartLocation = DroneLocaton;
		}
		
		FCoastBossShootBallActionParams ShootParams;
		const int NumWaveBalls = CoastBossConstants::ManyDronesBoss::Phase8Drones_AttackNumBullets;
		const float WaveSpeed = CoastBossConstants::ManyDronesBoss::Phase8Drones_AttackSpeed;
		const float AngleSpread = CoastBossConstants::ManyDronesBoss::Phase8Drones_AttackAngleSpread / NumWaveBalls;
		const float Sign = bClockwise ? 1.0 : -1.0;

		for (int iBall = 0; iBall < NumWaveBalls; ++iBall)
		{
			WaveAngle += AngleSpread * Sign;
			FCoastBossPlayerBulletData BulletData;
			float Y = Math::Sin(Math::DegreesToRadians(WaveAngle));
			float X = Math::Cos(Math::DegreesToRadians(WaveAngle));
			FVector2D Direction(X, Y);
			BulletData.Velocity = Direction * WaveSpeed;
			BulletData.Location = StartLocation;
			ShootParams.BulletDatas.Add(BulletData);
		}
		CoastBoss.AttackActionQueue.Capability(UCoastBossShootBallCapability, ShootParams); 
	}

	void ShootPingPongWave(FVector2D NormalDirection)
	{
		FCoastBossShootBallActionParams ShootParams;
		const int NumWaveBalls = CoastBossConstants::ManyDronesBoss::Phase4Drones_WaveAttackNumBullets;
		const float WaveSpeed = CoastBossConstants::ManyDronesBoss::Phase4Drones_WaveAttackSpeed;
		float RadianAngle = Math::DegreesToRadians(CoastBossConstants::ManyDronesBoss::Phase4Drones_WaveAttackAngleSpread);
		const float AngleSpread = RadianAngle / NumWaveBalls;

		float Angle = Math::Atan2(NormalDirection.Y, NormalDirection.X);
		Angle -= RadianAngle * 0.5;

		for (int iBall = 0; iBall < NumWaveBalls; ++iBall)
		{
			Angle += AngleSpread;
			FCoastBossPlayerBulletData BulletData;
			float Y = Math::Sin(Angle);
			float X = Math::Cos(Angle);
			FVector2D Direction(X, Y);
			BulletData.Velocity = Direction * WaveSpeed;
			BulletData.Location = CoastBoss.ManualRelativeLocation;
			ShootParams.BulletDatas.Add(BulletData);
		}
		CoastBoss.AttackActionQueue.Capability(UCoastBossShootBallCapability, ShootParams); 
	}

	void ChangeFormation(ECoastBossFormation NewFormation)
	{
		FCoastBossChangeShapeActionParams Data;
		Data.NewShape = NewFormation;
		CoastBoss.AttackActionQueue.Capability(UCoastBossChangeShapeCapability, Data); 
	}

};