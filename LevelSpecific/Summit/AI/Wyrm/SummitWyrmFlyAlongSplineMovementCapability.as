
class USummitWyrmFlyAlongSplineMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"FlyingMovement");	
	default CapabilityTags.Add(n"SplineMovement");	
	default TickGroupOrder = 60;

	bool bCapturedSpline = false;

	USummitWyrmSettings WyrmSettings;
	UCapsuleComponent CollisionComp;
	USimpleMovementData SlidingMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WyrmSettings = USummitWyrmSettings::GetSettings(Owner);
		CollisionComp = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		SlidingMovement = Cast<USimpleMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSimpleMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SlidingMovement);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DestinationComp.FollowSpline == nullptr)
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (DestinationComp.FollowSpline == nullptr)
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bCapturedSpline = false;
		// Just use start for now
		//float DistAlongSpline = DestinationComp.FollowSpline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
		float DistAlongSpline = 0.0;
		DestinationComp.FollowSplinePosition = FSplinePosition(DestinationComp.FollowSpline, DistAlongSpline, DestinationComp.bFollowSplineForwards);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.FollowSplinePosition = FSplinePosition();
		if (bCapturedSpline)
		{
			CollisionComp.SetCollisionProfileName(n"EnemyIgnoreCharacters");
		}
	}

	void ComposeMovement(float DeltaTime) override
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		FVector MoveDir = Owner.ActorForwardVector;

		// Move to spline, then follow along that spline
		if (!bCapturedSpline && Owner.ActorLocation.IsWithinDist(DestinationComp.FollowSplinePosition.WorldLocation, MoveSettings.SplineFollowCaptureDistance))
			CaptureSpline();

		float Speed;
		if (!bCapturedSpline)
		{
			// Move to spline
			// TODO: Use air pathfinding and try to align velocity with spline (approaching from behind spline position)
			MoveDir = (DestinationComp.FollowSplinePosition.WorldLocation - OwnLoc).GetSafeNormal();
			Velocity += MoveDir * DestinationComp.Speed * DeltaTime;				
			Velocity -= Velocity * MoveSettings.AirFriction * DeltaTime;
			Speed = Velocity.Size();
			Movement.AddVelocity(Velocity);
		}
		else
		{
			// Accelerate along spline
			FVector SplineDir = DestinationComp.FollowSplinePosition.WorldForwardVector;
			Velocity += SplineDir * DestinationComp.Speed * DeltaTime;
			Velocity -= Velocity * MoveSettings.AirFriction * DeltaTime;

			// Move along spline
			FVector PrevLocAlongSpline = DestinationComp.FollowSplinePosition.WorldLocation;
			float SplineSpeed = SplineDir.DotProduct(Velocity);
			DestinationComp.FollowSplinePosition.Move(SplineSpeed * DeltaTime);
			FVector DeltaAlongSpline = DestinationComp.FollowSplinePosition.WorldLocation - PrevLocAlongSpline;
			Movement.AddDelta(DeltaAlongSpline);

			// Adjust spline-orthogonal velocity
			FVector OrthogonalVelocity = Velocity;
			OrthogonalVelocity += (DestinationComp.FollowSplinePosition.WorldLocation - Owner.ActorLocation) * DestinationComp.Speed * 0.01 * DeltaTime; // Accelerate towards spline
			OrthogonalVelocity = OrthogonalVelocity.ConstrainToPlane(SplineDir);
			OrthogonalVelocity -= OrthogonalVelocity * MoveSettings.SplineCaptureBrakeFriction * DeltaTime;
			Movement.AddVelocity(OrthogonalVelocity);
			MoveDir = SplineDir; // TODO: factor in orthogonal velocity!
			Speed = SplineSpeed;
		}

		// Add velocity for undulation
		float UndulationTime = ActiveDuration * WyrmSettings.UndulationFrequency * 2.0;
		FVector UndulationDir = DestinationComp.FollowSplinePosition.WorldRightVector * Math::Sin(UndulationTime) * WyrmSettings.UndulationAmount;
		UndulationDir += DestinationComp.FollowSplinePosition.WorldUpVector * Math::Sin(UndulationTime * 0.2) * Math::Sin(UndulationTime) * WyrmSettings.UndulationAmount * 0.5;
		Movement.AddVelocity(UndulationDir * Speed * 0.5);
		
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * MoveSettings.AirFriction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of spline
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else 
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}

	void CaptureSpline()
	{
		bCapturedSpline = true;
		CollisionComp.SetCollisionProfileName(n"NoCollision");
	}
}
