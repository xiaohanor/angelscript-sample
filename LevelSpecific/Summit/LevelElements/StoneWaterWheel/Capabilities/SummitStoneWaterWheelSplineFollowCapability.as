class USummitStoneWaterWheelSplineFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	ASummitStoneWaterWheel Wheel;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	float Speed;

	const float RotationInterpSpeed = 20.0;
	const float LinearInterpSpeed = 20.0;
	const float MaxActiveDuration = 5.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Wheel = Cast<ASummitStoneWaterWheel>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!Wheel.bFollowExitSpline)
			return false;

		if(!Wheel.bIsActive)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!Wheel.bFollowExitSpline)
			return true;

		if(!Wheel.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Speed = MoveComp.Velocity.Size();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > MaxActiveDuration)
		{
			Wheel.DeactivateWheel();
			return;
		}

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector GroundNormal = MoveComp.CurrentGroundNormal;
				FVector Forward = GroundNormal.CrossProduct(-Wheel.ActorRightVector);

				FRotator SpeedRotation = GetRotationFromSpeed(DeltaTime);
				Wheel.RotationRoot.AddLocalRotation(SpeedRotation);
				Wheel.SyncRotationComp.SetValue(Wheel.RotationRoot.WorldRotation);

				FSplinePosition SplinePos = Wheel.FollowSplineActor.Spline.GetClosestSplinePositionToWorldLocation(Wheel.ActorLocation);

				FRotator Rotation = Wheel.ActorRotation;
				FRotator TargetRotation = SplinePos.WorldRotation.Rotator();
				TargetRotation.Pitch = Rotation.Pitch;
				TargetRotation.Roll = Rotation.Roll;
				Rotation = Math::RInterpTo(Rotation, TargetRotation, DeltaTime, RotationInterpSpeed);
				Movement.SetRotation(Rotation);

				FVector InterpedLocation = Wheel.ActorLocation;
				FVector TargetLocation = SplinePos.WorldLocation;
				TargetLocation.Z = InterpedLocation.Z;
				InterpedLocation = Math::VInterpTo(InterpedLocation, TargetLocation, DeltaTime, LinearInterpSpeed);
				FVector DeltaToInterpedLocation = InterpedLocation - Wheel.ActorLocation;
				Movement.AddDelta(DeltaToInterpedLocation * DeltaTime); 

				TEMPORAL_LOG(Wheel)
					.DirectionalArrow("Forward", Wheel.ActorLocation, Forward * 500, 10, 40, FLinearColor::Red)
					.DirectionalArrow("Ground Normal", Wheel.ActorLocation, GroundNormal * 500, 10, 40, FLinearColor::Blue)
					.DirectionalArrow("Delta To Interped Location", Wheel.ActorLocation, DeltaToInterpedLocation, 10, 40, FLinearColor::DPink)
					.DirectionalArrow("Velocity Forwards", Wheel.ActorLocation, Forward * Speed, 10, 40, FLinearColor::LucBlue)
					.Sphere("Spline Pos", SplinePos.WorldLocation, 100, FLinearColor::Purple, 5)
				;

				Movement.AddVelocity(Wheel.ActorForwardVector * Speed);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			// Remote update
			else
			{
				Wheel.RotationRoot.SetWorldRotation(Wheel.SyncRotationComp.Value);
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}

	FRotator GetRotationFromSpeed(float DeltaTime) const
	{
		FRotator Rotation;
		
		float CurrentSpeed = MoveComp.HorizontalVelocity.ConstrainToPlane(Wheel.ActorRightVector).Size();
		float RotationAngle = Math::RadiansToDegrees(-CurrentSpeed * DeltaTime / Wheel.CapsuleComp.CapsuleRadius);

		if(MoveComp.HorizontalVelocity.DotProduct(Wheel.ActorForwardVector) < 0)
			RotationAngle *= -1;

		Rotation = FRotator(RotationAngle, 0 , 0); 

		return Rotation;
	}	

};