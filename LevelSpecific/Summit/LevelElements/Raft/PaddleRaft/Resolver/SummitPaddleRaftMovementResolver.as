struct FSummitPaddleRaftMovementResolverImpactData
{
	FVector ImpactLocation;
	FVector ImpactNormal;
	float SpeedIntoImpact;
}

enum ESummitPaddleRaftHitSide
{
	LeftFront,
	RightFront,
	LeftBack,
	RightBack,
}

enum ESummitPaddleRaftHitStaggerSide
{
	Left,
	Right,
	Front,
	Back,
}

struct FSummitPaddleRaftHitStaggerData
{
	UPROPERTY()
	ESummitPaddleRaftHitStaggerSide HitSide;
	UPROPERTY()
	bool bSmallHit;
	bool bOverriddenPreviousData;
}

class USummitPaddleRaftMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = USummitPaddleRaftMovementData;
	private const USummitPaddleRaftMovementData MovementData;

	const float MinReflectionAngle = 0.0;
	const float MinReflectionSpeed = 0.0;

	const float AngularImpulseFraction = 0.2;
	const float MinAngularImpulse = 0.0;
	const float MaxAngularImpulse = 30.0;
	const float MaxYawSpeed = 45.0;
	const float MaxRollSpeed = 75.0;
	const float RollSpeedFraction = 0.5;

	const float MinRestitution = 0.5;
	const float MaxRestitution = 2.0;

	const float CameraImpulseMinSize = 5.0;
	const float CameraImpulseAngularMultiplier = 0.75;
	const float CameraImpulseMultiplier = 1.0;

	const float CollisionImpulseSizeThresholdForAdditionalImpulse = 40;

	TOptional<FSummitPaddleRaftMovementResolverImpactData> ImpactData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MovementData = Cast<USummitPaddleRaftMovementData>(Movement);
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

		const FVector CurrentHorizontalVelocity = State.GetDelta().GetHorizontalPart(MovementData.WaterUp).Velocity;
		const FVector FlatNormal = Hit.Normal.VectorPlaneProject(MovementData.WaterUp).GetSafeNormal();

		const float ReflectionAngle = CurrentHorizontalVelocity.GetAngleDegreesTo(FlatNormal);

		auto TemporalLog = TEMPORAL_LOG(Owner, "Reflect Along Water");
		TemporalLog
			.Arrow("Current Horizontal Velocity", Owner.ActorLocation, Owner.ActorLocation + CurrentHorizontalVelocity, 2, 20, FLinearColor::White)
			.Arrow("Flat Normal", Hit.ImpactPoint, Hit.ImpactPoint + FlatNormal * 50, 2, 20, FLinearColor::Black)
			.Arrow("Normal", Hit.ImpactPoint, Hit.ImpactPoint + Hit.Normal * 50, 2, 20, FLinearColor::Black)
			.Value("Reflection Angle", ReflectionAngle);

		if (ReflectionAngle < MinReflectionAngle)
			return false;

		FVector DirIntoImpact = FVector::ZeroVector;
		float SpeedIntoImpact = 0;
		CurrentHorizontalVelocity.ToDirectionAndLength(DirIntoImpact, SpeedIntoImpact);
		// if (SpeedIntoImpact < MinReflectionSpeed)
		// 	return false;
		float VelocityDot = Math::Abs(DirIntoImpact.DotProduct(-FlatNormal));

		// lower restitution when hitting something in front or behind, as we will also apply an angularimpulse to correct the boat rotation
		float Restitution = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(MinRestitution, MaxRestitution), 1 - VelocityDot);

		TemporalLog
			.Sphere("Impact Location", Hit.ImpactPoint, 20, FLinearColor::LucBlue, 5)
			// .DirectionalArrow("Dir To Impact", Owner.ActorLocation, DirToImpact * 50, 2, 20, FLinearColor::Green)
			.Value("Velocity into Impact", SpeedIntoImpact)
			.Value("VelocityDot", VelocityDot)
			.Value("Restitution", Restitution);

		for (auto It : State.DeltaStates)
		{
			FMovementDelta HorizontalDelta = It.Value.ConvertToDelta().GetHorizontalPart(MovementData.WaterUp);

			TemporalLog
				.Arrow(f"{It.Key} : Horizontal Velocity Pre Reflection", Hit.ImpactPoint - HorizontalDelta.Velocity, Hit.ImpactPoint, 2, 20, FLinearColor::Green);

			HorizontalDelta = HorizontalDelta.Bounce(FlatNormal, Restitution);

			TemporalLog
				.Arrow(f"{It.Key} : Horizontal Velocity Post Reflection", Hit.ImpactPoint, Hit.ImpactPoint + HorizontalDelta.Velocity, 2, 20, FLinearColor::Purple);

			// Disregarding vertical delta so we don't slide over or under when redirecting
			State.OverrideDelta(It.Key, HorizontalDelta);
		}

		FSummitPaddleRaftMovementResolverImpactData Data;
		Data.ImpactLocation = Hit.ImpactPoint;
		Data.ImpactNormal = Hit.ImpactNormal;
		Data.SpeedIntoImpact = SpeedIntoImpact;
		ImpactData.Set(Data);

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		if (ImpactData.IsSet())
		{
			auto Raft = Cast<APaddleRaft>(Owner);
			UPaddleRaftSettings RaftSettings = UPaddleRaftSettings::GetSettings(Raft);

			auto Data = ImpactData.Value;

			FVector DirToImpact = -ImpactData.Value.ImpactNormal;

			ESummitPaddleRaftHitSide HitOrientation;
			
			const bool bHitWasInFront = DirToImpact.DotProduct(Owner.ActorForwardVector) > 0;
			const bool bHitWasToTheRight = DirToImpact.DotProduct(Owner.ActorRightVector) > 0;

			if (bHitWasInFront)
			{
				if (bHitWasToTheRight)
					HitOrientation = ESummitPaddleRaftHitSide::RightFront;
				else
					HitOrientation = ESummitPaddleRaftHitSide::LeftFront;
			}
			else
			{
				if (bHitWasToTheRight)
					HitOrientation = ESummitPaddleRaftHitSide::RightBack;
				else
					HitOrientation = ESummitPaddleRaftHitSide::LeftBack;
			}

			float ImpulseSign;
			if (HitOrientation == ESummitPaddleRaftHitSide::LeftFront || HitOrientation == ESummitPaddleRaftHitSide::RightBack)
				ImpulseSign = 1.0;
			else
				ImpulseSign = -1.0;

			float ImpulseSize = Math::Clamp(Data.SpeedIntoImpact * AngularImpulseFraction, MinAngularImpulse, MaxAngularImpulse);
			float AngularImpulse = ImpulseSize * ImpulseSign;

			auto TemporalLog = TEMPORAL_LOG(Owner, "Reflect Along Water");
			TemporalLog.Value("bWasHitInFront", bHitWasInFront);
			TemporalLog.Value("bHitWasToTheRight", bHitWasToTheRight);

			// To fix if you are turning into the wall and still want the impulse to be noticeable
			if (Math::Sign(Raft.YawSpeed) != ImpulseSign)
				AngularImpulse -= Raft.YawSpeed;

			AngularImpulse = Math::Clamp(AngularImpulse, -MaxAngularImpulse, MaxAngularImpulse);
			Raft.YawSpeed += AngularImpulse;

			if (Math::Abs(Raft.YawSpeed) > MaxYawSpeed)
				Raft.YawSpeed = Math::Clamp(Raft.YawSpeed, -MaxYawSpeed, MaxYawSpeed);

			Raft.AccRoll.Velocity += AngularImpulse * RollSpeedFraction;
			if (Math::Abs(Raft.AccRoll.Velocity) > MaxRollSpeed)
				Raft.AccRoll.Velocity = Math::Clamp(Raft.AccRoll.Velocity, -MaxRollSpeed, MaxRollSpeed);

			TemporalLog
				.Value("Angular Impulse", AngularImpulse);

			if (ImpactData.Value.SpeedIntoImpact > RaftSettings.StaggerSpeedThreshold)
			{
				FSummitRaftHitStaggerData StaggerData;

				ESummitRaftHitStaggerSide HitSide;
				float DirFrontAlignment = Raft.ActorForwardVector.DotProduct(DirToImpact);
				if (DirFrontAlignment > RaftSettings.StaggerFrontAlignmentThreshold)
					HitSide = ESummitRaftHitStaggerSide::Front;
				else if (DirFrontAlignment < -RaftSettings.StaggerFrontAlignmentThreshold)
					HitSide = ESummitRaftHitStaggerSide::Back;
				else if (bHitWasToTheRight)
					HitSide = ESummitRaftHitStaggerSide::Right;
				else
					HitSide = ESummitRaftHitStaggerSide::Left;

				StaggerData.HitSide = HitSide;
				StaggerData.ImpactPoint = ImpactData.Value.ImpactLocation;
				if (ImpactData.Value.SpeedIntoImpact > RaftSettings.StaggerSpeedBigHitThreshold)
					StaggerData.bSmallHit = false;
				else
					StaggerData.bSmallHit = true;

				Raft.ApplyStaggerToBothPlayers(StaggerData);
			}

			ImpactData.Reset();
		}
	}
}