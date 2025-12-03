
class UCoastTrainCircuitLockeSplineMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"SplineMovement");	
	default TickGroupOrder = 60;

	bool bCapturedSpline = false;
	USimpleMovementData SlidingMovement;

	UCoastTrainCircuitLockeSplineMoveComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SlidingMovement = Cast<USimpleMovementData>(Movement);
		SplineComp = UCoastTrainCircuitLockeSplineMoveComponent::GetOrCreate(Owner);
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
		
		DestinationComp.FollowSplinePosition = FSplinePosition(DestinationComp.FollowSpline, SplineComp.DistanceAlongSpline, DestinationComp.bFollowSplineForwards);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplineComp.DistanceAlongSpline = DestinationComp.FollowSplinePosition.GetCurrentSplineDistance();
		DestinationComp.FollowSplinePosition = FSplinePosition();
	}

	void ComposeMovement(float DeltaTime) override
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		FVector MoveDir = Owner.ActorForwardVector;

		// Move to spline, then follow along that spline
		if (!bCapturedSpline && Owner.ActorLocation.IsWithinDist(DestinationComp.FollowSplinePosition.WorldLocation, MoveSettings.SplineFollowCaptureDistance))
			CaptureSpline();

		if (!bCapturedSpline)
		{
			// Move to spline
			// TODO: Use air pathfinding and try to align velocity with spline (approaching from behind spline position)
			MoveDir = (DestinationComp.FollowSplinePosition.WorldLocation - OwnLoc).GetSafeNormal();
			Velocity += MoveDir * DestinationComp.Speed * DeltaTime;				
			Velocity -= Velocity * MoveSettings.AirFriction * DeltaTime;
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
			Movement.AddDelta(DestinationComp.FollowSplinePosition.WorldLocation - PrevLocAlongSpline);

			// Adjust spline-orthogonal velocity
			FVector OrthogonalVelocity = Velocity.ConstrainToPlane(SplineDir);
			OrthogonalVelocity -= OrthogonalVelocity * MoveSettings.SplineCaptureBrakeFriction * DeltaTime;
			Movement.AddVelocity(OrthogonalVelocity);
			MoveDir = SplineDir; // TODO: factor in orthogonal velocity!
		}
		
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
	}
}