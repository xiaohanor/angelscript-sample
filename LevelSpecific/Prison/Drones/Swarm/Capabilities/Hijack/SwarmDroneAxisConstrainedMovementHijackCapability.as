class USwarmDroneAxisConstrainedMovementHijackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;

	ASwarmDroneSimpleMovementHijackable SimpleMovementHijackableOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SimpleMovementHijackableOwner = Cast<ASwarmDroneSimpleMovementHijackable>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SimpleMovementHijackableOwner == nullptr)
			return false;

		if (SimpleMovementHijackableOwner.MovementSettings.HijackType != ESwarmDroneSimpleMovementHijackType::AxisConstrained)
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
		SimpleMovementHijackableOwner.Velocity = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SimpleMovementHijackableOwner.Velocity = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FVector Input = GetMassagedInputVector(GetUpVectorForConstraint());
			// Debug::DrawDebugDirectionArrow(Owner.ActorLocation, Input, Input.Size() * 200.0, 5, FLinearColor::DPink);

			float DecelerationInterpSpeed = Math::Pow(1.0 - Input.Size(), 3.0);
			float Acceleration = Math::Lerp(SimpleMovementHijackableOwner.MovementSettings.Acceleration, SimpleMovementHijackableOwner.MovementSettings.Deceleration, DecelerationInterpSpeed);

			FVector TargetVelocity = Input * SimpleMovementHijackableOwner.MovementSettings.MaxSpeed;
			SimpleMovementHijackableOwner.Velocity = Math::VInterpTo(SimpleMovementHijackableOwner.Velocity, TargetVelocity, DeltaTime, Acceleration * DeltaTime);

			// Add boundaries
			FVector MoveDelta = SimpleMovementHijackableOwner.Velocity * DeltaTime;
			FVector NextLocation = Owner.ActorLocation + MoveDelta;
			FVector Overshoot = (GetBoundToTest() - NextLocation).GetSafeNormal();

			// Stop at constraints
			float Offset = MoveDelta.DotProduct(Overshoot);
			if (Offset < 0.0)
			{
				// Eman TODO: Filip went and changed this to prevent the velocity from becoming infinite and crashing the game.
				// See commit 9419b43017d182a827d132105fbc9dddf6b9e481 and 9c02782e2aa3aa446e8e4684c9ca4b7cda692e2c
				// I'm still not quite sure what happened, but OverShoot was not normalized, which could cause issues when Offset was calculated since it wasn't just the length of MoveDelta projected on Overshoot,
				// and on top of that Velocity was added to instead of set, which I changed to just a hard clamp to prevent the bouncing that caused the crash.
				FVector Test = GetBoundToTest();
				SimpleMovementHijackableOwner.Velocity = FVector::ZeroVector;
				MoveDelta = Test - Owner.ActorLocation;
			}

			Owner.AddActorWorldOffset(MoveDelta);
		}
		else
		{
			Owner.SetActorLocation(SimpleMovementHijackableOwner.CrumbSyncedPositionComponent.GetPosition().WorldLocation);
			Owner.SetActorRotation(SimpleMovementHijackableOwner.CrumbSyncedPositionComponent.GetPosition().WorldRotation);
		}
	}

	FVector GetMassagedInputVector(FVector UpVector)
	{
		// Adjust up vector depending on which side of the plane we are
		// Debug::DrawDebugDirectionArrow(Owner.ActorLocation, UpVector, 300, 5, FLinearColor::LucBlue);

		AHazePlayerCharacter Player = SimpleMovementHijackableOwner.HijackComponent.GetHijackPlayer();

		// Get cancer-free player camera rotation (no shakes and noise)
		FRotator ViewRotation = Player.GetUnmodifiedViewInfo().Rotation;

		// Get forward vector based on current view rotation and player up
		FVector ForwardVector;
		if (Math::Abs(UpVector.DotProduct(ViewRotation.RightVector)) < 0.99)
			ForwardVector = ViewRotation.RightVector.CrossProduct(UpVector).GetSafeNormal();
		else
		 	ForwardVector = ViewRotation.ForwardVector.ConstrainToPlane(UpVector).GetSafeNormal();

		if (ForwardVector.IsZero())
			ForwardVector = ViewRotation.UpVector.ConstrainToPlane(UpVector).GetSafeNormal();

		//Can also be done by multiplying with sign result
		FRotator YawRotation = FRotator(0.0, Player.ViewRotation.Yaw, 0.0);
		if (UpVector.DotProduct(YawRotation.Vector()) > 0.0)
			ForwardVector.Z = -Math::Abs(ForwardVector.Z);
		else
			ForwardVector.Z = Math::Abs(ForwardVector.Z);

		// Get right vector using new forward
		FVector RightVector = UpVector.CrossProduct(ForwardVector);

		const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector Input = (ForwardVector * Math::Pow(RawStick.X, 2.0) * Math::Sign(RawStick.X)) + (RightVector * Math::Pow(RawStick.Y, 2.0) * Math::Sign(RawStick.Y));
		
		Input = Input.ConstrainToDirection(SimpleMovementHijackableOwner.MovementSettings.AxisConstrainedSettings.GetConstraintVector());

		return Input;
	}

	// Ugh so nasty...
	FVector GetUpVectorForConstraint()
	{
		FVector WorldAxisConstraint = SimpleMovementHijackableOwner.GetWorldAxisConstraint();

		FVector AdjustedConstraint = SimpleMovementHijackableOwner.HijackComponent.GetHijackPlayer().GetViewRotation().ForwardVector.CrossProduct(WorldAxisConstraint).GetSafeNormal();
		if (SimpleMovementHijackableOwner.MovementSettings.AxisConstrainedSettings.AxisConstrainType == ESwarmDroneAxisConstrainedMovementHijackType::Z)
		{
			FVector WorldConstraintRightVector = WorldAxisConstraint.CrossProduct(SimpleMovementHijackableOwner.HijackComponent.GetHijackPlayer().GetViewRotation().ForwardVector).GetSafeNormal();
			AdjustedConstraint = -WorldConstraintRightVector.CrossProduct(WorldAxisConstraint).GetSafeNormal();
		}
		else
		{
			const float CameraUpDotConstraint = AdjustedConstraint.DotProduct(SimpleMovementHijackableOwner.HijackComponent.GetHijackPlayer().GetViewRotation().UpVector);
			AdjustedConstraint *= Math::Sign(CameraUpDotConstraint);
		}

		return AdjustedConstraint;
	}

	FVector GetBoundToTest()
	{
		if (SimpleMovementHijackableOwner.Velocity.DotProduct(SimpleMovementHijackableOwner.MovementSettings.AxisConstrainedSettings.GetConstraintVector()) > 0.0)
			return SimpleMovementHijackableOwner.StaticWorldAxisBounds.PositiveBound;

		return SimpleMovementHijackableOwner.StaticWorldAxisBounds.NegativeBound;
	}
}