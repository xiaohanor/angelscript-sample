UCLASS(NotBlueprintable)
class USandSharkMovementComponent : UActorComponent
{
	access Internal = private, ASandShark;

	access:Internal TInstigated<ASandSharkSpline> CurrentSpline;

	ASandShark SandShark;

	FSplinePosition SplinePosition;
	FHazeAcceleratedFloat AccDive;
	FHazeAcceleratedFloat AccMovementSpeed;

	float AngularSpeed;
	uint LastMoveFrame = 0;
	FInstigator LastMoveInstigator;
	USandSharkSettings SharkSettings;
	float TimeWhenLastMoved = 0;

	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SandShark = Cast<ASandShark>(Owner);

		SyncedActorPositionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(SandShark, n"SyncedPosition");

		SyncedActorPositionComp.OverrideSyncDetailLevel(EHazeActorPositionSyncDetailLevel::Player);
		SyncedActorPositionComp.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		CurrentSpline.Apply(SandShark::Spline::GetClosestSpline(SandShark.ActorLocation), this, EInstigatePriority::Low);
		AccDive.SnapTo(SandShark::Idle::Height);
		SharkSettings = USandSharkSettings::GetSettings(SandShark);
		AccMovementSpeed.SnapTo(SharkSettings.IdleMovement.MovementSpeed);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(SandShark).Section("Movement");

		TemporalLog.Sphere("ActorLocation", SandShark.ActorLocation, 100);
		if (Desert::HasLandscapeForLevel(SandShark.LandscapeLevel) && Desert::GetRelevantLandscapeLevel() == SandShark.LandscapeLevel)
			TemporalLog.Sphere("SandLocation", Desert::GetLandscapeLocationByLevel(SandShark.ActorLocation, SandShark.LandscapeLevel), 100, FLinearColor::LucBlue);
		TemporalLog.Value(f"ActorVelocity", SandShark.ActorVelocity);
		TemporalLog.Value(f"AccDive", AccDive.Value);
		TemporalLog.Value(f"AccMovementSpeed", AccMovementSpeed.Value);
		TemporalLog.Value(f"AngularSpeed", AngularSpeed);
		TemporalLog.Value(f"LastMoveFrame", LastMoveFrame);
		TemporalLog.Value(f"HasMovedThisFrame", HasMovedThisFrame());
		TemporalLog.Value(f"LastMoveInstigator", LastMoveInstigator);
		TemporalLog.Value(f"Splines;CurrentSpline", CurrentSpline.Get());

		auto DistractionSplines = SandShark.GetQueuedDistractionSplines();
		for (int i = 0; i < DistractionSplines.Num(); i++)
		{
			TemporalLog.Value(f"Splines;DistractionSpline{i};Spline", DistractionSplines[i].Spline);
			TemporalLog.Value(f"Splines;DistractionSpline{i};TimeWhenStarted", DistractionSplines[i].TimeWhenStarted);
			TemporalLog.Value(f"Splines;DistractionSpline{i};bIsValid", DistractionSplines[i].bIsValid);
		}
	}
#endif

	/**
	 * The MoveComp knows if we have moved this frame by setting the last move frame in ApplyMove()
	 * We can use this to make sure that only one capability moves the shark every frame.
	 * We use this same pattern on the player. The nice benefit of this is that capabilities sort of waterfall down
	 * the tick order, so early tick moving capabilities apply a move, and late tick capabilities deactivate.
	 */
	bool HasMovedThisFrame() const
	{
		return LastMoveFrame == Time::FrameNumber;
	}

	FQuat GetAlignWithGroundRotation() const
	{
		FVector HeadLocation = SandShark.ActorLocation;
		FVector BackLocation = SandShark.ActorLocation - SandShark.ActorForwardVector * 600;

		float HeadHeight = Desert::GetLandscapeHeightByLevel(HeadLocation, SandShark.LandscapeLevel);
		float BackHeight = Desert::GetLandscapeHeightByLevel(BackLocation, SandShark.LandscapeLevel);

		HeadLocation.Z = HeadHeight;
		BackLocation.Z = BackHeight;

		return FQuat::MakeFromXZ(HeadLocation - BackLocation, FVector::UpVector);
	}

	float CalculateNavigationAngle(FVector CurrentLocation, FVector TargetLocation, float PredictAheadDistance)
	{
		// Navigate along the nav mesh
		UNavigationPath Path = UNavigationSystemV1::FindPathToLocationSynchronously(CurrentLocation, TargetLocation);

		float TurnAngle;
		if (Path == nullptr || !Path.IsValid() || Path.IsPartial())
		{
			// Found no path or only partial path, ignore navigation!
			TurnAngle = CalculateAngleToTargetLocation(TargetLocation);
		}
		else
		{
			// Create a RuntimeSpline with the path points to smooth it out
			FHazeRuntimeSpline RuntimeSpline;
			RuntimeSpline.SetPoints(Path.PathPoints);
			TurnAngle = CalculateAngleToRuntimeSpline(RuntimeSpline, PredictAheadDistance);
		}
		return TurnAngle;
	}

	void MoveNavigateToLocation(FSandSharkMovementData MoveData, FVector Location, float DeltaTime, float InMovementSpeed, FInstigator Instigator)
	{
		const FVector CurrentLandscapeLocation = Desert::GetLandscapeLocationByLevel(SandShark.ActorLocation, SandShark.LandscapeLevel);
		const FVector TargetLandscapeLocation = Desert::GetLandscapeLocationByLevel(Location, SandShark.LandscapeLevel);

		const float TurnAngle = CalculateNavigationAngle(CurrentLandscapeLocation, TargetLandscapeLocation, 500);

		const FQuat CurrentRotation = GetAlignWithGroundRotation();

		float TurnSpeed = MoveData.TurnSpeed;
		float TargetTurnAngle = Math::Clamp(TurnAngle, -MoveData.MaxTurnAngle, MoveData.MaxTurnAngle);

		FQuat TargetRotation = FQuat(FVector::UpVector, Math::DegreesToRadians(TargetTurnAngle)) * CurrentRotation;
		FQuat NewRotation = CurrentRotation.ForwardVector.RotateTowards(TargetRotation.ForwardVector, TurnSpeed * DeltaTime).ToOrientationQuat();

		float TurnAlpha = Math::Saturate(Math::Abs(TurnAngle) / MoveData.MaxTurnAngle);
		float TargetMovementSpeed = Math::Lerp(InMovementSpeed, MoveData.MovementSpeedTurning, TurnAlpha);
		AccMovementSpeed.AccelerateTo(TargetMovementSpeed, MoveData.AccelerationDuration, DeltaTime);

		FVector NewLocation = Desert::GetLandscapeLocation(SandShark.ActorLocation + NewRotation.ForwardVector * AccMovementSpeed.Value * DeltaTime);

		ApplyMove(NewLocation, NewRotation, Instigator);
	}

	void MoveNavigateToLocationNoOvershoot(FSandSharkMovementData MoveData, FVector Location, float DeltaTime, float InMovementSpeed, FInstigator Instigator)
	{
		const FVector CurrentLandscapeLocation = Desert::GetLandscapeLocationByLevel(SandShark.ActorLocation, SandShark.LandscapeLevel);
		const FVector TargetLandscapeLocation = Desert::GetLandscapeLocationByLevel(Location, SandShark.LandscapeLevel);

		const float TurnAngle = CalculateNavigationAngle(CurrentLandscapeLocation, TargetLandscapeLocation, 50);

		const FQuat CurrentRotation = SandShark.ActorQuat;

		float TurnSpeed = MoveData.TurnSpeed;
		float TargetTurnAngle = Math::Clamp(TurnAngle, -MoveData.MaxTurnAngle, MoveData.MaxTurnAngle);
		FQuat NewRotation;
		FQuat TargetRotation = FQuat(FVector::UpVector, Math::DegreesToRadians(TargetTurnAngle)) * CurrentRotation;
		if (TurnSpeed * DeltaTime < Math::Abs(TargetTurnAngle))
		{
			NewRotation = CurrentRotation.ForwardVector.RotateTowards(TargetRotation.ForwardVector, TurnSpeed * DeltaTime).ToOrientationQuat();
			float TurnAlpha = Math::Saturate(Math::Abs(TurnAngle) / MoveData.MaxTurnAngle);
			float TargetMovementSpeed = Math::Lerp(InMovementSpeed, MoveData.MovementSpeedTurning, TurnAlpha);
			AccMovementSpeed.AccelerateTo(TargetMovementSpeed, MoveData.AccelerationDuration, DeltaTime);
		}
		else
		{
			NewRotation = TargetRotation;
			AccMovementSpeed.AccelerateTo(InMovementSpeed, MoveData.AccelerationDuration, DeltaTime);
		}

		FVector NewLocation = Desert::GetLandscapeLocation(SandShark.ActorLocation + NewRotation.ForwardVector * AccMovementSpeed.Value * DeltaTime);

		ApplyMove(NewLocation, NewRotation, Instigator);
	}

	void ApplyMove(FVector Location, FInstigator Instigator)
	{
		ApplyMove(Location, SandShark.ActorQuat, Instigator);
	}

	/**
	 * Apply the move, and store that we did a move this frame for HasMovedThisFrame().
	 * We also store the instigator for debugging.
	 */
	void ApplyMove(FVector NewWorldLocation, FQuat NewWorldRotation, FInstigator Instigator)
	{
		// check(HasControl());
		check(!HasMovedThisFrame());
		const FVector Delta = NewWorldLocation - SandShark.ActorLocation;
		SetVelocity(Delta / Time::GetActorDeltaSeconds(SandShark));

		SandShark.SetActorLocationAndRotation(NewWorldLocation, NewWorldRotation);
		LastMoveFrame = Time::FrameNumber;
		LastMoveInstigator = Instigator;
		TimeWhenLastMoved = Time::GameTimeSeconds;
	}

	/**
	 * When networking, we don't want to apply a move since that would cause desyncs.
	 * Instead we get the actor position and rotation from the SyncedActorPosition component.
	 * That component *should* automatically replicate the actor transform, but I haven't tested this one yet.
	 */
	void ApplyCrumbSyncedLocationAndRotation(FInstigator Instigator)
	{
		check(!HasControl());
		check(!HasMovedThisFrame());
		const FHazeSyncedActorPosition SyncedPosition = SyncedActorPositionComp.GetPosition();

		const FVector Delta = SyncedPosition.WorldLocation - SandShark.ActorLocation;

		// if position hasn't changed on remote it might be because we haven't received new data
		if (!Delta.IsNearlyZero())
			SetVelocity(Delta / Time::GetActorDeltaSeconds(SandShark));

		SandShark.SetActorLocationAndRotation(SyncedPosition.WorldLocation, SyncedPosition.WorldRotation);
		LastMoveFrame = Time::FrameNumber;
		LastMoveInstigator = Instigator;
		TimeWhenLastMoved = Time::GameTimeSeconds;
	}

	float CalculateAngleToPlayer() const
	{
		return CalculateAngleToTargetLocation(SandShark.GetTargetPlayer().ActorLocation);
	}

	float CalculateAngleToRuntimeSpline(FHazeRuntimeSpline RuntimeSpline, float PredictAheadDistance) const
	{
		const float ClosestDistance = RuntimeSpline.GetClosestSplineDistanceToLocation(SandShark.ActorLocation);
		const float AheadDistance = ClosestDistance + PredictAheadDistance;

		const FVector TargetLocation = RuntimeSpline.GetLocationAtDistance(AheadDistance);

		return CalculateAngleToTargetLocation(TargetLocation);
	}

	float CalculateAngleToSpline(UHazeSplineComponent Spline, float PredictAheadDistance) const
	{
		const float ClosestDistance = Spline.GetClosestSplineDistanceToWorldLocation(SandShark.ActorLocation);
		const float AheadDistance = ClosestDistance + PredictAheadDistance;

		const FVector TargetLocation = Spline.GetWorldLocationAtSplineDistance(AheadDistance);

		return CalculateAngleToTargetLocation(TargetLocation);
	}

	float CalculateAngleToTargetLocation(FVector TargetLocation) const
	{
		const FVector Delta = TargetLocation - SandShark.ActorLocation;
		const FVector DirectionToTarget = Delta.GetSafeNormal();

		const FVector ForwardHorizontal = SandShark.ActorForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		const FVector DirectionToTargetHorizontal = DirectionToTarget.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		float Angle = ForwardHorizontal.GetAngleDegreesTo(DirectionToTargetHorizontal);

		// Flip the angle if the direction is to the left of the shark
		Angle = (DirectionToTargetHorizontal.DotProduct(SandShark.ActorRightVector) > 0) ? Angle : -Angle;

		return Angle;
	}

	void UpdateMoveSplinePosition(FSplinePosition InSplinePosition)
	{
		check(HasControl());
		SplinePosition = InSplinePosition;
	}

	void ApplyCurrentSplineInstigator(ASandSharkSpline NewSpline, FInstigator Instigator, EInstigatePriority Priority)
	{
		CurrentSpline.Apply(NewSpline, Instigator, Priority);

		if (CurrentSpline.Get() == nullptr)
			return;

		FSplinePosition NewSplinePosition = CurrentSpline.Get().Spline.GetClosestSplinePositionToWorldLocation(SandShark.ActorLocation, true);
		NewSplinePosition.MatchFacingTo(SandShark.ActorQuat);
		if (HasControl())
			UpdateMoveSplinePosition(NewSplinePosition);
	}

	void RemoveCurrentSplineByInstigator(FInstigator Instigator)
	{
		CurrentSpline.Clear(Instigator);
		if (CurrentSpline.Get() == nullptr)
			return;

		FSplinePosition NewSplinePosition = CurrentSpline.Get().Spline.GetClosestSplinePositionToWorldLocation(SandShark.ActorLocation, true);
		NewSplinePosition.MatchFacingTo(SandShark.ActorQuat);
		if (HasControl())
			UpdateMoveSplinePosition(NewSplinePosition);
	}

	FVector GetVelocity() const
	{
		return SandShark.ActorVelocity;
	}

	void SetVelocity(FVector InVelocity)
	{
		SandShark.SetActorVelocity(InVelocity);
	}
};