struct FGravityBikeSplineEnemyMissileRelativeMovementData
{
	FTransform RelativeToSplineTransform;
	FHazeAcceleratedFloat AccMoveSpeed;

	FVector PreviousLocation;
	FVector WorldLocation;
	FQuat WorldRotation;

	private FQuat SplineRotation;
	private uint AppliedFrame = 0;
	private FInstigator PrepareInstigator;

	FGravityBikeSplineEnemyMissileRelativeMovementData(
		FTransform InitialWorldTransform,
		FTransform InitialSplineTransform,
		float FlyStraightMoveSpeed)
	{
		WorldLocation = InitialWorldTransform.Location;
		WorldRotation = InitialWorldTransform.Rotation;
		SplineRotation = InitialSplineTransform.Rotation;

		const FVector RelativeLocation = InitialSplineTransform.InverseTransformPositionNoScale(WorldLocation);
		const FQuat RelativeRotation = InitialSplineTransform.InverseTransformRotation(WorldRotation);
		RelativeToSplineTransform = FTransform(RelativeRotation, RelativeLocation);

		AccMoveSpeed.SnapTo(FlyStraightMoveSpeed);
	}

	void Prepare(FVector InWorldLocation, FQuat InWorldRotation, FInstigator Instigator)
	{
		check(!PrepareInstigator.IsValid());

		PreviousLocation = WorldLocation;
		WorldLocation = InWorldLocation;
		WorldRotation = InWorldRotation;
		PrepareInstigator = Instigator;
	}

	void AddRelativeVelocity(FVector SplineLocation, FVector RelativeVelocity, float DeltaTime)
	{
		check(!RelativeVelocity.IsZero());
		
		const FTransform SplineTransform(SplineRotation, SplineLocation); 

		const FVector OldRelativeLocation = RelativeToSplineTransform.Location;
		const FVector NewRelativeLocation = OldRelativeLocation + RelativeVelocity * DeltaTime;

		RelativeToSplineTransform.SetLocation(NewRelativeLocation);
		RelativeToSplineTransform.SetRotation(FQuat::MakeFromXZ(RelativeVelocity, FVector::UpVector));

		WorldLocation = SplineTransform.TransformPositionNoScale(NewRelativeLocation);
		WorldRotation = SplineTransform.TransformRotation(RelativeToSplineTransform.Rotation);
	}

	void AddWorldVelocity(FVector WorldVelocity, float DeltaTime)
	{
		WorldLocation = WorldLocation + (WorldVelocity * DeltaTime);
		FQuat TargetRotation = FQuat::MakeFromXZ(WorldVelocity, SplineRotation.UpVector);
		WorldRotation = Math::QInterpTo(WorldRotation, TargetRotation, DeltaTime, 5);
	}

	void VInterpConstantTo(FVector TargetLocation, float DeltaTime, float InterpSpeed)
	{
		WorldLocation = Math::VInterpConstantTo(WorldLocation, TargetLocation, DeltaTime, InterpSpeed);
	}

	void TickFlyStraight(FVector SplineLocation, float FlyStraightMoveSpeed, float DeltaTime)
	{
		const FVector RelativeVelocity = RelativeToSplineTransform.Rotation.ForwardVector * FlyStraightMoveSpeed;
		AddRelativeVelocity(SplineLocation, RelativeVelocity, DeltaTime);
	}

	/**
	 * @return Finished turning around
	 */
	bool TickTurnAround(FVector SplineLocation, float TurnAroundMoveSpeed, float TurnAroundTurnSpeed, float DeltaTime, FVector TargetWorldDirection)
	{
		AccMoveSpeed.AccelerateTo(TurnAroundMoveSpeed, 1, DeltaTime);

		const FTransform SplineTransform(SplineRotation, SplineLocation);

		const FVector RelativeTargetDirection = SplineTransform.InverseTransformVectorNoScale(TargetWorldDirection);
		const FQuat TargetBack = FQuat::MakeFromXZ(RelativeTargetDirection, FVector::UpVector);
		
		// Turn around
		// Every now and then, I get a little bit lonely
		const FQuat CurrentRotation = RelativeToSplineTransform.Rotation;
		const FQuat NewRotation = Math::QInterpTo(CurrentRotation, TargetBack, DeltaTime, TurnAroundTurnSpeed);

		const FVector RelativeVelocity = NewRotation.ForwardVector * AccMoveSpeed.Value;
		AddRelativeVelocity(SplineLocation, RelativeVelocity, DeltaTime);

		const float BackDot = CurrentRotation.ForwardVector.DotProduct(RelativeTargetDirection);
		if(BackDot > 0.8)
			return true;
		else
			return false;
	}

	void TickHoming(FVector SplineLocation, float HomingMoveSpeed, float HomingTurnSpeed, float DeltaTime, FVector TargetWorldLocation)
	{
		const FTransform SplineTransform(SplineRotation, SplineLocation);

		AccMoveSpeed.AccelerateTo(HomingMoveSpeed, 1, DeltaTime);

		const FVector RelativeTargetLocation = SplineTransform.InverseTransformPositionNoScale(TargetWorldLocation);

		const FVector RelativeTargetDirection = (RelativeTargetLocation - RelativeToSplineTransform.Location);
		const FQuat RelativeTargetRotation = FQuat::MakeFromXZ(RelativeTargetDirection, FVector::UpVector);
		const FQuat NewRelativeRotation = Math::QInterpTo(RelativeToSplineTransform.Rotation, RelativeTargetRotation, DeltaTime, HomingTurnSpeed);

		FVector RelativeVelocity = NewRelativeRotation.ForwardVector * AccMoveSpeed.Value;
		AddRelativeVelocity(SplineLocation, RelativeVelocity, DeltaTime);
	}

	void ApplyOnActor(AHazeActor Actor, float DeltaTime)
	{
		FVector Delta = WorldLocation - Actor.ActorLocation;
		FVector Velocity = Delta / DeltaTime;
		Actor.SetActorVelocity(Velocity);

		Actor.SetActorLocationAndRotation(WorldLocation, WorldRotation);

		ApplyHandled();
	}

	void ApplyHandled()
	{
		AppliedFrame = Time::FrameNumber;
		PrepareInstigator = FInstigator();
	}

	bool HasAppliedMovementThisFrame() const
	{
		return AppliedFrame == Time::FrameNumber;
	}
};