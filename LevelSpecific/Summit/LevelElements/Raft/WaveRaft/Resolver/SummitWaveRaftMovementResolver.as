struct FSummitWaveRaftMovementResolverImpactData
{
	FVector NewDirection;
	float PostReflectionAngleFromSpline;
	float SpeedIntoImpact;
	FVector ImpactNormal;
	FVector ReflectedVelocity;
	FVector ImpactPoint;
}

// struct FSummitWaveRaftHitStaggerData
// {
// 	UPROPERTY()
// 	bool bRightSide;

// 	UPROPERTY()
// 	bool bSmallHit;

// 	bool bOverriddenPreviousData;
// }

class USummitWaveRaftMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = USummitWaveRaftMovementData;
	private const USummitWaveRaftMovementData MovementData;

	const float MinReflectionAngle = 20.0;
	const float DeathAngle = 50.0;

	const float CameraImpulseSize = 20.0;
	const float CameraImpulseAngularMultiplier = 0.1;

	bool bIgnoreUnderwaterCollision = true;

	TOptional<FSummitWaveRaftMovementResolverImpactData> ImpactData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MovementData = Cast<USummitWaveRaftMovementData>(Movement);
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		if (ReflectAlongWater(IterationState, Hit))
		{
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool ReflectAlongWater(FMovementResolverState& State, FMovementHitResult Hit) const
	{
		if (!Hit.IsValidBlockingHit())
			return false;

		if (!Hit.IsWallImpact())
			return false;

		// if normal is more or less aligned with waterup then we ignore it
		if (bIgnoreUnderwaterCollision && Hit.Normal.DotProduct(MovementData.WaterUp) >= 0.9)
			return false;

		if (MovementData.WaveRaft.StaggerData.IsSet())
			return false;

		const FVector CurrentHorizontalVelocity = State.GetDelta().GetHorizontalPart(MovementData.WaterUp).Velocity;
		const FVector FlatNormal = Hit.Normal.VectorPlaneProject(MovementData.WaterUp).GetSafeNormal();

		const float ReflectionAngle = CurrentHorizontalVelocity.GetAngleDegreesTo(FlatNormal);

		auto TemporalLog = TEMPORAL_LOG(Owner, "Reflect Along Water");
		TemporalLog
			.Arrow("Current Horizontal Velocity", Owner.ActorLocation, Owner.ActorLocation + CurrentHorizontalVelocity, 2, 20, FLinearColor::White)
			.Arrow("Flat Normal", Hit.ImpactPoint, Hit.ImpactPoint + FlatNormal * 50, 2, 20, FLinearColor::Black)
			.Arrow("Normal", Hit.ImpactPoint, Hit.ImpactPoint + Hit.Normal * 50, 2, 20, FLinearColor::Black)
			.Value("Reflection Angle", ReflectionAngle);

		// if (ReflectionAngle < MinReflectionAngle)
		// 	return false;

		//Print(f"{ReflectionAngle=}", 5);

		float SpeedIntoImpact = CurrentHorizontalVelocity.DotProduct(-FlatNormal);

		TemporalLog
			.Value("Velocity into Impact", SpeedIntoImpact);

		for (auto It : State.DeltaStates)
		{
			FMovementDelta HorizontalDelta = It.Value.ConvertToDelta().GetHorizontalPart(MovementData.WaterUp);

			TemporalLog
				.Arrow(f"{It.Key} : Horizontal Velocity Pre Reflection", Hit.ImpactPoint - HorizontalDelta.Velocity, Hit.ImpactPoint, 2, 20, FLinearColor::Green);

			HorizontalDelta = HorizontalDelta.Bounce(FlatNormal, 2);

			TemporalLog
				.Arrow(f"{It.Key} : Horizontal Velocity Post Reflection", Hit.ImpactPoint, Hit.ImpactPoint + HorizontalDelta.Velocity, 2, 20, FLinearColor::Purple);

			// Disregarding vertical delta so we don't slide over or under when redirecting
			State.OverrideDelta(It.Key, HorizontalDelta);
		}
		FSummitWaveRaftMovementResolverImpactData Data;
		Data.ReflectedVelocity = State.GetDelta().Velocity;
		// Data.NewDirection = Hit.Normal.CrossProduct(MovementData.WaterUp) * 0.5;
		// Data.PostReflectionAngleFromSpline = PostReflectionAngleFromSpline;
		Data.SpeedIntoImpact = SpeedIntoImpact;
		Data.ImpactNormal = Hit.Normal;
		Data.ImpactPoint = Hit.ImpactPoint;
		ImpactData.Set(Data);

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		if (ImpactData.IsSet())
		{
			auto Raft = Cast<AWaveRaft>(Owner);
			auto RaftSettings = UWaveRaftSettings::GetSettings(Raft);

			auto Data = ImpactData.Value;
			//float RotationSpeed = 40.0 * Time::GetActorDeltaSeconds(Cast<AHazeActor>(MovementComponent.Owner));
			FVector ProjectedNormal = Data.ImpactNormal.VectorPlaneProject(MovementData.WaterUp);

			bool bHitWasToTheRight = -ProjectedNormal.DotProduct(Raft.ActorRightVector) > 0;

			// if (!bHitWasToTheRight)
			// 	RotationSpeed *= -1;
			Raft.TargetYawOffsetFromSpline = 0;

			FHazeCameraImpulse CameraImpulse;
			float CamImpulseSize = CameraImpulseSize;
			if (!bHitWasToTheRight)
				CamImpulseSize *= -1;
			CameraImpulse.AngularImpulse = FRotator(0, CamImpulseSize * CameraImpulseAngularMultiplier, 0);

			FVector CameraImpulseDir = MovementData.SplinePos.WorldRightVector;
			FVector WorldSpaceCameraImpulse = CameraImpulseDir * CamImpulseSize;
			CameraImpulse.WorldSpaceImpulse = WorldSpaceCameraImpulse;
			CameraImpulse.Dampening = 0.7;
			CameraImpulse.ExpirationForce = 10.0;
			SceneView::FullScreenPlayer.ApplyCameraImpulse(CameraImpulse, this);

			if (Data.SpeedIntoImpact > RaftSettings.StaggerSpeedThreshold)
			{
				FSummitRaftHitStaggerData StaggerData;

				ESummitRaftHitStaggerSide HitSide;
				if (bHitWasToTheRight)
					HitSide = ESummitRaftHitStaggerSide::Right;
				else
					HitSide = ESummitRaftHitStaggerSide::Left;

				StaggerData.HitSide = HitSide;
				StaggerData.HitNormal = Data.ImpactNormal;
				StaggerData.ReflectedVelocity = Data.ReflectedVelocity;
				StaggerData.ImpactPoint = Data.ImpactPoint;
				if (Data.SpeedIntoImpact > RaftSettings.StaggerSpeedBigHitThreshold)
					StaggerData.bSmallHit = false;
				else
					StaggerData.bSmallHit = true;

				Raft.ApplyStaggerData(StaggerData);
			}

			ImpactData.Reset();
		}
	}
}