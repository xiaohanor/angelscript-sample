class UCoastBossMoveBulletsCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	// default TickGroupOrder = 110;

	ACoastBoss CoastBoss;
	UCoastBossAeronauticComponent MioComp;
	UCoastBossAeronauticComponent ZoeComp;

	bool bHackyMadeHealthBarAppear = false;
	ACoastBoss2DPlane ConstrainPlane;
	ACoastBossDrillbazzTelegraph DrillbazzTelegraph;
	float DrillbazzActiveDuration = 0.0;
	bool bWasDrillbazzing = false;

	TArray<ACoastBossBulletBall> BallUnspawns;
	TArray<ACoastBossBulletBall> AutoBallUnspawns;
	TArray<ACoastBossBulletMill> MillUnspawns;
	TArray<ACoastBossBulletMine> MineUnspawns;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoastBoss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (CoastBossDevToggles::Draw::DrawDebugBoss.IsEnabled())
		// {
		// 	Debug::DrawDebugSphere(Owner.ActorLocation, 500.0, 12, ColorDebug::Ruby, 10.0, 0.0, true);
		// 	Debug::DrawDebugLine(Owner.ActorLocation, Game::Mio.ActorCenterLocation, ColorDebug::Ruby, 20.0);
		// }

		if (!TryCacheThings())
			return;

		for (int iBall = 0; iBall < CoastBoss.ActiveBalls.Num(); ++iBall)
			UpdateBalls(CoastBoss.ActiveBalls[iBall], DeltaTime);
		for (int iUnspawn = 0; iUnspawn < BallUnspawns.Num(); ++iUnspawn)
			BallUnspawns[iUnspawn].RespawnComp.UnSpawn();
		BallUnspawns.Empty();

		for (int iBall = 0; iBall < CoastBoss.ActiveAutoBalls.Num(); ++iBall)
			UpdateAutoBalls(CoastBoss.ActiveAutoBalls[iBall], DeltaTime);
		for (int iUnspawn = 0; iUnspawn < AutoBallUnspawns.Num(); ++iUnspawn)
			AutoBallUnspawns[iUnspawn].RespawnComp.UnSpawn();
		AutoBallUnspawns.Empty();

		for (int iMill = 0; iMill < CoastBoss.ActiveMills.Num(); ++iMill)
			UpdateMills(CoastBoss.ActiveMills[iMill], DeltaTime);
		for (int iUnspawn = 0; iUnspawn < MillUnspawns.Num(); ++iUnspawn)
			MillUnspawns[iUnspawn].RespawnComp.UnSpawn();
		MillUnspawns.Empty();

		for (int iMine = 0; iMine < CoastBoss.ActiveMines.Num(); ++iMine)
			UpdateMines(CoastBoss.ActiveMines[iMine], DeltaTime);
		for (int iUnspawn = 0; iUnspawn < MineUnspawns.Num(); ++iUnspawn)
			MineUnspawns[iUnspawn].RespawnComp.UnSpawn();
		MineUnspawns.Empty();

		if (CoastBoss.CurrentFormation == ECoastBossFormation::State12_Drillbazz)
			UpdateDrillbazz(DeltaTime);
		else
		{
			bWasDrillbazzing = false;
			DrillbazzTelegraph.MeshComp.SetVisibility(false);
			DrillbazzActiveDuration = 0.0;
		}
	}

	void UpdateBalls(ACoastBossBulletBall Ball, float DeltaSeconds)
	{
		Ball.AliveDuration += DeltaSeconds;

		Ball.ExtraImpulse.AccelerateTo(1.0, 0.5, DeltaSeconds);
		Ball.Velocity += Ball.Acceleration * DeltaSeconds;
		Ball.Velocity.Y += Ball.Gravity * DeltaSeconds;
		Ball.AccScale.SpringTo(Ball.TargetScale, 50.0, 0.9, DeltaSeconds);
		float Scaling = Math::Clamp(Ball.AccScale.Value, 0.1, 500.0);
		Ball.MeshComp.SetWorldScale3D(FVector::OneVector * Scaling);
		Ball.InitialVelocity.AccelerateTo(FVector2D::ZeroVector, 0.2, DeltaSeconds);
		Ball.ManualRelativeLocation += Ball.Velocity * Ball.ExtraImpulse.Value * DeltaSeconds + Ball.InitialVelocity.Value;
		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(Ball.ManualRelativeLocation);
		FRotator BulletRotation = FRotator::MakeFromXZ(ConstrainPlane.ActorRightVector, ConstrainPlane.ActorUpVector);

		Ball.SetActorLocationAndRotation(WorldLocation, BulletRotation);
		OffsetBallMeshInFrontOfBoss(Ball);

		if (Ball.AliveDuration > Ball.MaxAliveTime || CoastBoss.bDead || ConstrainPlane.IsOutsideOfPlaneX(Ball.ManualRelativeLocation))
		{
			Ball.bDangerous = false;
			Ball.Gravity = -980.0 * 2.0;
			Ball.TargetScale = 0.1;
		}

		bool bScaledDown = Scaling < 0.1 + KINDA_SMALL_NUMBER && Ball.TargetScale < 1.0 - KINDA_SMALL_NUMBER;
		if (bScaledDown || Ball.BallData.bHitSomething || ConstrainPlane.IsOutsideOfPlaneY(Ball.ManualRelativeLocation))
			BallUnspawns.Add(Ball);
	}

	void UpdateAutoBalls(ACoastBossBulletBall Ball, float DeltaSeconds)
	{
		Ball.AliveDuration += DeltaSeconds;

		Ball.ExtraImpulse.AccelerateTo(1.0, 0.5, DeltaSeconds);
		Ball.Velocity += Ball.Acceleration * DeltaSeconds;
		Ball.Velocity.Y += Ball.Gravity * DeltaSeconds;
		Ball.AccScale.SpringTo(Ball.TargetScale, 50.0, 0.9, DeltaSeconds);
		float Scaling = Math::Clamp(Ball.AccScale.Value, 0.1, 500.0);
		Ball.MeshComp.SetWorldScale3D(FVector::OneVector * Scaling);
		Ball.ManualRelativeLocation += Ball.Velocity * Ball.ExtraImpulse.Value * DeltaSeconds;
		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(Ball.ManualRelativeLocation);
		FRotator BulletRotation = FRotator::MakeFromXZ(ConstrainPlane.ActorRightVector, ConstrainPlane.ActorUpVector);

		Ball.SetActorLocationAndRotation(WorldLocation, BulletRotation);
		OffsetBallMeshInFrontOfBoss(Ball);

		if (Ball.AliveDuration > Ball.MaxAliveTime || CoastBoss.bDead || ConstrainPlane.IsOutsideOfPlaneX(Ball.ManualRelativeLocation))
		{
			Ball.bDangerous = false;
			Ball.Gravity = -980.0 * 2.0;
			Ball.TargetScale = 0.1;
		}

		bool bScaledDown = Scaling < 0.1 + KINDA_SMALL_NUMBER && Ball.TargetScale < 1.0 - KINDA_SMALL_NUMBER;
		if (bScaledDown || Ball.BallData.bHitSomething || ConstrainPlane.IsOutsideOfPlaneY(Ball.ManualRelativeLocation))
			AutoBallUnspawns.Add(Ball);
	}

	void OffsetBallMeshInFrontOfBoss(ACoastBossBulletBall Ball)
	{
		// Get the chord of a circle based on how far away ball is from boss
		//		 ━━━━━━━━━
		//		/	  O━b━\
		//     /	 a┃ ╱c \
		//	   ┃	  O    ┃
		//     \	       ╱
		// 		\	      ╱
		//       ━━━━━━━━━
		// a = dist from ball to boss
		// b = unknown, the chord of the circle that we want to calculate (which is how much we'll offset the mesh)
		// c = hypotenuse which is just the radius of the circle
		// b = sqrt(sqr(c) - sqr(a))
		const float Radius = CoastBossConstants::BigDroneBoss::BigBossOffsetShootBallsRadius;
		float Dist = Ball.ActorLocation.Distance(CoastBoss.ActorLocation);
		float OffsetDistance = 0.0;
		if(Dist < Radius)
		{
			OffsetDistance = Math::Sqrt(Math::Square(Radius) - Math::Square(Dist));
		}

		Ball.MeshComp.WorldLocation = Ball.ActorLocation - ConstrainPlane.ActorForwardVector * OffsetDistance;
	}

	void UpdateMills(ACoastBossBulletMill Mill, float DeltaSeconds)
	{
		Mill.AliveDuration += DeltaSeconds;
		
		Mill.ExtraImpulse.AccelerateTo(1.0, 1.0, DeltaSeconds);
		Mill.Velocity += Mill.Acceleration * DeltaSeconds;
		Mill.Velocity.Y += Mill.Gravity * DeltaSeconds;
		Mill.AccScale.AccelerateTo(Mill.TargetScale, 5.0, DeltaSeconds);
		float Scaling = Math::Clamp(Mill.AccScale.Value, 0.1, 500.0);
		Mill.ScaleValue = Scaling / 500.0;
		for (int iMesh = 0; iMesh < Mill.MillData.MillBlades.Num(); ++iMesh)
		{
			FVector Scale = Mill.MillData.MillBlades[iMesh].GetWorldScale();
			Scale.Z = Scaling;
			Mill.MillData.MillBlades[iMesh].SetWorldScale3D(Scale);
		}
		
		Mill.MillData.RotationAngle += -30.0 * DeltaSeconds;
		Mill.MillData.RotationAngle = Math::Wrap(Mill.MillData.RotationAngle, 0.0, 90.0);
		Mill.ManualRelativeLocation += Mill.Velocity * Mill.ExtraImpulse.Value * DeltaSeconds;
		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(Mill.ManualRelativeLocation);
		FRotator BulletRotation = Mill.ActorRotation; 
		BulletRotation.Pitch = Mill.MillData.RotationAngle;

// #if EDITOR
// 		TEMPORAL_LOG(CoastBoss, "Mills").Sphere("Mill " + Mill.GetName(), WorldLocation, 100.0, ColorDebug::White);
// #endif

		Mill.SetActorLocation(WorldLocation);
		Mill.SetActorRotation(BulletRotation);

		if (Mill.MillData.HitTimes > Mill.TimesToHit || Mill.AliveDuration > Mill.MaxAliveTime || ConstrainPlane.IsOutsideOfPlaneX(Mill.ManualRelativeLocation))
		{
			Mill.Gravity = -980.0 * 2.0;
			Mill.TargetScale = 0.1;
		}

		if (ConstrainPlane.IsOutsideOfPlaneY(Mill.ManualRelativeLocation))
			MillUnspawns.Add(Mill);

		// Debug::DrawDebugString(WorldLocation, "" + Mill.ManualRelativeLocation);
		// Debug::DrawDebugCoordinateSystem(Mill.ActorLocation, Mill.ActorRotation, 500.0, 5.0, 0.0, true);
		// Debug::DrawDebugCoordinateSystem(ConstrainPlane.ActorLocation, ConstrainPlane.ActorRotation, 500.0, 5.0, 0.0, true);
		// Debug::DrawDebugPlane(Mill.ActorLocation, Mill.ActorRotation.RightVector, 500.0, 500.0);
	}

	void UpdateMines(ACoastBossBulletMine Mine, float DeltaSeconds)
	{
		Mine.AliveDuration += DeltaSeconds;
		
		Mine.Velocity += Mine.Acceleration * DeltaSeconds;
		Mine.Velocity.Y += Mine.Gravity * DeltaSeconds;
		Mine.AccScale.AccelerateTo(Mine.MineData.TargetScale, 1.0, DeltaSeconds);
		float Scaling = Math::Clamp(Mine.AccScale.Value, 0.1, Mine.MineData.TargetScale);
		Mine.MeshComp.SetWorldScale3D(FVector::OneVector * Scaling);

		Mine.BeepCooldown -= DeltaSeconds;
		if (Mine.BeepCooldown < 0.0)
		{
			float BeepIntensityAlpha = Mine.AliveDuration / Mine.MaxAliveTime;
			Mine.BeepInterval = Math::Lerp(Mine.SlowBeepInterval, Mine.FastBeepInterval, BeepIntensityAlpha);
			Mine.BeepCooldown = Mine.BeepInterval;
			FCoastBossBulletMineBeepData Params;
			Params.TimeUntilNextBeep = Mine.BeepCooldown;
			Mine.Beep();
			UCoastBossBulletMineEventHandler::Trigger_Beep(Mine, Params);
		}

		Mine.InitialVelocity.AccelerateTo(FVector2D::ZeroVector, 0.5, DeltaSeconds);
		FVector2D Move = Mine.Velocity;
		Move += Mine.InitialVelocity.Value;

		if(!Mine.TargetPlayer.IsPlayerDead() || !Mine.TargetPlayer.OtherPlayer.IsPlayerDead())
		{
			AHazePlayerCharacter Player = Mine.TargetPlayer;
			if(Player.IsPlayerDead())
				Player = Player.OtherPlayer;

			FVector NewMineLocation = ConstrainPlane.GetLocationInWorld(Mine.ManualRelativeLocation);
			FVector TowardsPlayer = Player.ActorLocation - NewMineLocation;
			FVector2D TowardsOnPlane = ConstrainPlane.GetDirectionOnPlane(TowardsPlayer);
			Move += TowardsOnPlane.GetSafeNormal() * Mine.FollowSpeed;
#if EDITOR
			TEMPORAL_LOG(Mine)
				.Point("PlayerLocation", Player.ActorLocation, 15.f, FLinearColor::Red)
				.DirectionalArrow("TowardsPlayer", Mine.ActorLocation, TowardsPlayer * 1000.0, 5.0f)
				.Value("TowardsOnPlane", TowardsOnPlane)
			;
#endif
		}

		Mine.ManualRelativeLocation += Move * DeltaSeconds;
		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(Mine.ManualRelativeLocation);
		Mine.AccRot.AccelerateTo(FRotator::ZeroRotator, 2, DeltaSeconds);
		Mine.ActorQuat = ((Mine.AccRot.Value.Quaternion() * DeltaSeconds) * Mine.ActorQuat);
		Mine.ActorQuat = (Math::RotatorFromAxisAndAngle(FVector::UpVector, 5.0).Quaternion() * DeltaSeconds) * Mine.ActorQuat;
		Mine.ActorQuat = (Math::RotatorFromAxisAndAngle(FVector::RightVector, 3.0).Quaternion() * DeltaSeconds) * Mine.ActorQuat;

		Mine.SetActorLocation(WorldLocation);

		if (ConstrainPlane.IsOutsideOfPlaneX(Mine.ManualRelativeLocation))
		{
			Mine.Gravity = -980.0 * 2.0;
			Mine.SetDangerous(false);
		}

		if (Mine.MineData.bDetonated)
			Mine.MineData.DetonatedFeedbackDuration += DeltaSeconds;

		if (Mine.MineData.DetonatedFeedbackDuration > 0.1 || ConstrainPlane.IsOutsideOfPlaneY(Mine.ManualRelativeLocation))
		{
			Mine.MeshComp.SetVisibility(true);
			Mine.AreaFeedbackMeshComp.SetVisibility(false);
			MineUnspawns.Add(Mine);
		}
	}

	void UpdateDrillbazz(float DeltaSeconds)
	{
		if (!bWasDrillbazzing)
		{
			bWasDrillbazzing = false;
			DrillbazzTelegraph.MeshComp.SetVisibility(true);
		}
		DrillbazzActiveDuration += DeltaSeconds;
		
		if (DrillbazzActiveDuration < CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzWindUpDuration)
			CoastBoss.WhirlwindAlpha = DrillbazzActiveDuration / CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzWindUpDuration;
		else if (DrillbazzActiveDuration > CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzAttackDuration)
		{
			float Durationy = DrillbazzActiveDuration - CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzAttackDuration;
			CoastBoss.WhirlwindAlpha = 1.0 - Math::Clamp(Durationy / CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzFadeoutWindDuration, 0.0, 1.0);
		}
		
		FRotator Rotation = FRotator::MakeFromZX(-ConstrainPlane.ActorRightVector, ConstrainPlane.ActorUpVector);
		FVector Location = ConstrainPlane.GetLocationInWorld(CoastBoss.ManualRelativeLocation) - Rotation.UpVector * CoastBossConstants::ManyDronesBoss::Phase12Drones_DrillbazzWhirlwindOffset;
		DrillbazzTelegraph.SetActorLocationAndRotation(Location, Rotation, true);
		DrillbazzTelegraph.MeshComp.SetScalarParameterValueOnMaterials(n"Alpha", CoastBoss.WhirlwindAlpha);

		if (CoastBossDevToggles::Draw::DrawDebugBoss.IsEnabled())
			Debug::DrawDebugString(Location, "Shield\nAlpha:" + CoastBoss.WhirlwindAlpha, ColorDebug::Carrot, 0.0, 2.0);
	}

	bool TryCacheThings()
	{
		if (MioComp == nullptr)
			MioComp = UCoastBossAeronauticComponent::Get(Game::Mio);
		if (ZoeComp == nullptr)
			ZoeComp = UCoastBossAeronauticComponent::Get(Game::Zoe);
		if (ConstrainPlane == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
			{
				ConstrainPlane = Refs.Single.CoastBossPlane2D;
				DrillbazzTelegraph = Refs.Single.DrillbazzTelegraph;
			}
		}
		return MioComp != nullptr && ZoeComp != nullptr && ConstrainPlane != nullptr && DrillbazzTelegraph != nullptr;
	}
};