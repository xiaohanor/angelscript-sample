enum ECoastBoss2DPlaneMovementType
{
	None,
	Backup,
	BossBattle,
	AboveTrain
}

class UCoastBoss2DPlaneMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::BeforeMovement;
	// This is 30 because it has to be before other boss capabilities with BeforeMovement but still after DoubleInteractionCapability that is at TickGroupOrder 29
	// because that starts the boss capabilities.
	default TickGroupOrder = 30;

	ACoastBoss2DPlane Plane;

	FHazeAcceleratedFloat AccAdditionalOffset;
	float TargetOffsetToTrain = 0.0;
	float RandomOffsetDuration = 0.0;
	float RandomOffsetTimer = 0.0;

	float BackupSplineDistance = 0.0;
	ACoastTrainDriver TrainDriver;

	ACoastBossActorReferences References;

	const float OutOfImageOffset = -58000.0;
	const float InsideImageOffset = -9000.0;

	ECoastBoss2DPlaneMovementType CurrentMovementType = ECoastBoss2DPlaneMovementType::None;
	ECoastBoss2DPlaneMovementType PreviousMovementType = ECoastBoss2DPlaneMovementType::None;
	float MoveTypeLerpDuration = 0.0;
	bool bLerpDone = true;
	float TimeOfSwitchState = -100.0;
	bool bScaleCameraSpline = false;

	UCoastBossAeronauticComponent MioAeronauticComp;
	TOptional<float> TargetDistBetweenCameraSplineAndPlaneSpline;
	float BaseCameraSplineRadius;
	bool bInitialSnap = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Plane = Cast<ACoastBoss2DPlane>(Owner);
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
	void OnActivated()
	{
		MioAeronauticComp = UCoastBossAeronauticComponent::GetOrCreate(Game::Mio);
		if (!CacheTrain())
			return;

		if (!TryCacheThings())
			return;

		TargetOffsetToTrain = GetTargetOffsetToTrainLocation();
		AccAdditionalOffset.SnapTo(TargetOffsetToTrain);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!CacheTrain())
			return;
		Move2DPlane(DeltaTime);

		if(bScaleCameraSpline && TryCacheThings())
		{
			ASplineActor Spline = References.Camera.CustomCameraSpline;
			if(CurrentMovementType == ECoastBoss2DPlaneMovementType::BossBattle && bLerpDone)
			{
				Spline.ActorScale3D = FVector::OneVector;
				bScaleCameraSpline = false;
				return;
			}

			FVector PlaneMoveSplineLocation = Plane.MoveSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Plane.ActorLocation);
			if(!TargetDistBetweenCameraSplineAndPlaneSpline.IsSet())
			{
				FVector CameraSplineLocation = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(Plane.ActorLocation);
				TargetDistBetweenCameraSplineAndPlaneSpline.Set(PlaneMoveSplineLocation.Distance(CameraSplineLocation));
				BaseCameraSplineRadius = CameraSplineLocation.DistXY(Spline.ActorLocation);;
			}

			float CurrentDistance = PlaneMoveSplineLocation.DistXY(Plane.ActorLocation);
			float TargetCameraSplineRadius = BaseCameraSplineRadius + CurrentDistance;
			float TargetScale = TargetCameraSplineRadius / BaseCameraSplineRadius;
			Spline.ActorScale3D = FVector(TargetScale, TargetScale, 1.0);
		}

		if (CoastBossDevToggles::Draw::Draw2DPlane.IsEnabled())
		{
			Debug::DrawDebugPlane(Plane.ActorLocation, Plane.ActorForwardVector, Plane.PlaneExtents.Y, Plane.PlaneExtents.X, ColorDebug::White, 0.0, 8, 5.0);
			// Debug::DrawDebugArrow(ActorLocation, ActorLocation + ActorRightVector * 1500.0, 150.0, ColorDebug::Ruby, 10.0, 0.0, true);
		}
	}

	private bool CacheTrain()
	{
		if (TrainDriver == nullptr)
		{
			TrainDriver = CoastTrain::GetMainTrainDriver();
		}
		return TrainDriver != nullptr;
	}

	private void Move2DPlane(float DeltaTime)
	{
		HandleChangeMoveType();

		FVector CurrentLocation = GetPlaneLocationForMoveType(CurrentMovementType, DeltaTime);
		if(!bLerpDone && PreviousMovementType != ECoastBoss2DPlaneMovementType::None)
		{
			FVector PreviousLocation = GetPlaneLocationForMoveType(PreviousMovementType, DeltaTime);
			float Alpha = Time::GetGameTimeSince(TimeOfSwitchState) / MoveTypeLerpDuration;
			if(Alpha > 1.0)
			{
				Alpha = 1.0;
				bLerpDone = true;
			}

			Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
			CurrentLocation = Math::Lerp(PreviousLocation, CurrentLocation, Alpha);
		}

		Plane.SetActorLocation(CurrentLocation);
		FVector ToCenter = (CurrentLocation - Plane.MoveSpline.ActorLocation);
		ToCenter.Z = 0.0;
		Plane.SetActorRotation(FRotator::MakeFromXZ(ToCenter.GetSafeNormal(), FVector::UpVector));
	}

	void HandleChangeMoveType()
	{
		if(TrainDriver == nullptr)
			ChangeMoveType(ECoastBoss2DPlaneMovementType::Backup, 0.0);
		else if(MioAeronauticComp.bShouldPlayerEnter)
			ChangeMoveType(ECoastBoss2DPlaneMovementType::AboveTrain, 0.0);
		else
			ChangeMoveType(ECoastBoss2DPlaneMovementType::BossBattle, CurrentMovementType == ECoastBoss2DPlaneMovementType::AboveTrain ? 10.0 : 0.0);
	}

	void ChangeMoveType(ECoastBoss2DPlaneMovementType NewType, float LerpDuration)
	{
		if(NewType == CurrentMovementType)
			return;

		PreviousMovementType = CurrentMovementType;
		CurrentMovementType = NewType;
		TimeOfSwitchState = Time::GetGameTimeSeconds();
		MoveTypeLerpDuration = LerpDuration;
		if(LerpDuration > 0.0)
			bLerpDone = false;

		if(CurrentMovementType == ECoastBoss2DPlaneMovementType::AboveTrain)
			bScaleCameraSpline = true;
	}

	FVector GetPlaneLocationForMoveType(ECoastBoss2DPlaneMovementType Type, float DeltaTime)
	{
		switch(Type)
		{
			case ECoastBoss2DPlaneMovementType::None:
			{
				devError("Tried to get plane location for movement type none which is invalid!");
				return FVector::ZeroVector;
			}
			case ECoastBoss2DPlaneMovementType::Backup:
			{
				return GetBackupPlaneTransform(DeltaTime);
			}
			case ECoastBoss2DPlaneMovementType::BossBattle:
			{
				return GetBossBattlePlaneTransform(DeltaTime);
			}
			case ECoastBoss2DPlaneMovementType::AboveTrain:
			{
				return GetPlaneTransformAboveTrain(DeltaTime);
			}
		}
	}

	FVector GetBackupPlaneTransform(float DeltaTime)
	{
		BackupSplineDistance += 7000.0 * DeltaTime;
		BackupSplineDistance = Math::Wrap(BackupSplineDistance, 0.0, Plane.MoveSpline.Spline.SplineLength);
		return Plane.MoveSpline.Spline.GetWorldLocationAtSplineDistance(BackupSplineDistance);
	}

	FVector GetPlaneTransformAboveTrain(float DeltaTime)
	{
		ACoastTrainDriver Driver = CoastTrain::GetMainTrainDriver();
		FVector Location = Driver.ActorLocation + Driver.ActorTransform.TransformVector(FVector(-11000.0, 0.0, 0.0));
		Location.Z = Plane.MoveSpline.ActorLocation.Z;
		return Location;
	}

	FVector GetBossBattlePlaneTransform(float DeltaTime)
	{
		if (TryCacheThings())
		{
			TargetOffsetToTrain = GetTargetOffsetToTrainLocation();
			if(References.Boss.bShouldDevKill)
				AccAdditionalOffset.SnapTo(TargetOffsetToTrain);
		}

		float SinOffset = Math::Sin(Time::GameTimeSeconds * 0.3) * 700;

		AccAdditionalOffset.AccelerateTo(TargetOffsetToTrain, 15.0, DeltaTime);

		float DriverSplineDistance = Plane.MoveSpline.Spline.GetClosestSplineDistanceToWorldLocation(TrainDriver.ActorLocation) + AccAdditionalOffset.Value + SinOffset;
		float Alpha = Math::Wrap(DriverSplineDistance / Plane.MoveSpline.Spline.SplineLength, 0.0, 1.0);
		FQuat Temp(FVector::UpVector, PI * 2.0 * Alpha);
		float NewSplineAlpha = Math::Wrap(Temp.Rotator().Yaw / 360.0, 0.0, 1.0);
		FVector SplineLocation = Plane.MoveSpline.Spline.GetWorldLocationAtSplineDistance(Plane.MoveSpline.Spline.SplineLength * NewSplineAlpha);

		if (CoastBossDevToggles::Draw::DrawDebugTrain.IsEnabled())
		{
			Debug::DrawDebugString(Plane.ActorLocation, "" + NewSplineAlpha, ColorDebug::White, 0.0, 3.0);
			Debug::DrawDebugLine(Plane.ActorLocation, TrainDriver.ActorLocation, ColorDebug::Magenta, 10.0, 0.0);
		}

		return SplineLocation;
	}

	float GetTargetOffsetToTrainLocation()
	{
		if(References.Boss.bShouldDevKill)
		{
			if(!References.Boss.bDead && Time::GetGameTimeSince(References.Boss.TimeOfDevKill) > 0.2)
				References.Boss.BossDied(Game::Zoe);

			return InsideImageOffset;
		}

		if (References.Boss.bDead || !References.Boss.bStarted)
			return InsideImageOffset;
		else if (References.Boss.GetPhase() == CoastBossConstants::LastPhase)
		{
			if (CoastBossDevToggles::UseManyDrones.IsEnabled())
			{
				if (References.Boss.PhaseNumWeakpoints > 0)
				{
					float FloatyWeakpoints = References.Boss.PhaseNumWeakpoints;
					float FloatyWeakpointsKilled = References.Boss.DronesKilledDuringPhase;
					float ProgressAlpha = Math::Clamp(FloatyWeakpointsKilled / FloatyWeakpoints, 0.0, 1.0);
					return Math::Lerp(OutOfImageOffset, InsideImageOffset, ProgressAlpha);
				}
			}
			else
			{
				return Math::Lerp(OutOfImageOffset, InsideImageOffset, References.Boss.GetPingPongAlpha());
			}
		}
		
		return OutOfImageOffset;
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
};