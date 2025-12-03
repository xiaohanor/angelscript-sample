class UCoastBossMoveDronesCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 91;

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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TryCacheThings();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TryCacheThings())
			return;

		for (int iDrone = 0; iDrone < CoastBoss.DroneActors.Num(); ++iDrone)
			UpdateDrones(CoastBoss.DroneActors[iDrone], DeltaTime);
	}

	void UpdateDrones(ACoastBossDroneActor Drone, float DeltaSeconds)
	{
		// Drone.AliveDuration += DeltaSeconds;

		// Drone.Velocity += Drone.Acceleration * DeltaSeconds;
		// Drone.Velocity.Y += Drone.Gravity * DeltaSeconds;
		// Drone.AccScale.SpringTo(Drone.TargetScale, 50.0, 0.9, DeltaSeconds);
		// float Scaling = Math::Clamp(Drone.AccScale.Value, 0.1, 500.0);
		// Drone.MeshComp.SetWorldScale3D(FVector::OneVector * Scaling);
		// Drone.ManualRelativeLocation += Drone.Velocity * DeltaSeconds;

		Drone.AccManualRelativeLocation.AccelerateTo(Drone.TargetManualRelativeLocation, 1.0, DeltaSeconds);
		Drone.ActualRelativeLocation = Drone.AccManualRelativeLocation.Value;
		if (CoastBoss.BossPitchRadians > KINDA_SMALL_NUMBER)
		{
			// rotate on plane
			FVector2D Direction = Drone.ActualRelativeLocation.GetSafeNormal();
			float CurrentAngle = Math::Atan2(Direction.Y, Direction.X);
			Direction.Y = Math::Sin(CurrentAngle + CoastBoss.BossPitchRadians);
			Direction.X = Math::Cos(CurrentAngle + CoastBoss.BossPitchRadians);
			Drone.ActualRelativeLocation = Direction * Drone.ActualRelativeLocation.Size();
		}
		
		if (Drone.bAddBossLocation)
			Drone.ActualRelativeLocation += CoastBoss.ManualRelativeLocation;

		FRotator DroneRotation = FRotator::MakeFromXZ(-ConstrainPlane.ActorRightVector, ConstrainPlane.ActorUpVector);
		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(Drone.ActualRelativeLocation);
		if (CoastBoss.BossRollRadians > KINDA_SMALL_NUMBER)
		{
			FVector RelativeToPlane = WorldLocation - ConstrainPlane.ActorLocation;
			WorldLocation = ConstrainPlane.ActorLocation + FQuat(DroneRotation.ForwardVector, CoastBoss.BossRollRadians).RotateVector(RelativeToPlane);
		}
		Drone.SetActorLocationAndRotation(WorldLocation, DroneRotation);

		// if (Drone.AliveDuration > Drone.MaxAliveTime || ConstrainPlane.IsOutsideOfPlaneX(Drone.ManualRelativeLocation))
		// {
		// 	Drone.Gravity = -980.0 * 2.0;
		// 	Drone.TargetScale = 0.1;
		// }

		// bool bScaledDown = Scaling < 0.1 + KINDA_SMALL_NUMBER && Drone.TargetScale < 1.0 - KINDA_SMALL_NUMBER;
		// if (bScaledDown || Drone.DroneData.bHitSomething || ConstrainPlane.IsOutsideOfPlaneY(Drone.ManualRelativeLocation))
		// 	DroneUnspawns.Add(Drone);
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
