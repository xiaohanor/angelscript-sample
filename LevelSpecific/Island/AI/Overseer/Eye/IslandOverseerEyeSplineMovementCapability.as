struct FIslandOverseerEyeSplineMovementCapabilityActivateParams
{
	FSplinePosition SplinePosition;
};

class UIslandOverseerEyeSplineMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"FlyingMovement");	
	default CapabilityTags.Add(n"SplineMovement");	
	default TickGroupOrder = 60;

	bool bCapturedSpline = false;
	FHazeAcceleratedFloat AccSpeedAlongSpline;
	FHazeAcceleratedFloat AccCaptureAlpha;
	USimpleMovementData SlidingMovement;
	AAIIslandOverseerEye Eye;
	FHazeAcceleratedRotator AccRot;
	UHazeCrumbSyncedRotatorComponent SyncedRotator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SlidingMovement = Cast<USimpleMovementData>(Movement);
		Eye = Cast<AAIIslandOverseerEye>(Owner);
		SyncedRotator = UHazeCrumbSyncedRotatorComponent::Get(Owner);
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
	bool ShouldActivate(FIslandOverseerEyeSplineMovementCapabilityActivateParams& Params) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DestinationComp.FollowSpline == nullptr)
			return false;

		Params.SplinePosition = DestinationComp.FollowSplinePosition;
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
	void OnActivated(FIslandOverseerEyeSplineMovementCapabilityActivateParams Params)
	{
		Super::OnActivated();
		bCapturedSpline = false;
		DestinationComp.FollowSplinePosition = Params.SplinePosition;
		AccSpeedAlongSpline.SnapTo(0.0);
		AccCaptureAlpha.SnapTo(0.0);
		AccRot.SnapTo(Eye.MeshOffsetComponent.WorldRotation);
	}

	void ComposeMovement(float DeltaTime) override
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity;
		FVector MoveDir = Eye.MeshOffsetComponent.ForwardVector;

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
			// Adjust spline-orthogonal velocity to smooth over transition
			AccCaptureAlpha.AccelerateTo(1.0, 5.0, DeltaTime);
			FVector OrthogonalVelocity = Velocity.ConstrainToPlane(DestinationComp.FollowSplinePosition.WorldForwardVector);
			OrthogonalVelocity -= OrthogonalVelocity * 10.0 * DeltaTime;
			OrthogonalVelocity *= 1.0 - AccCaptureAlpha.Value;
			Movement.AddVelocity(OrthogonalVelocity);

			// Adjust orthogonal offset to hit spline but never overshoot
			Movement.AddDelta((DestinationComp.FollowSplinePosition.WorldLocation - Owner.ActorLocation) * AccCaptureAlpha.Value);

			// Accelerate along spline, ignoring physics
			float FollowSign = (DestinationComp.bFollowSplineForwards ? 1 : -1); 
			AccSpeedAlongSpline.AccelerateTo(DestinationComp.Speed * FollowSign, 2.0, DeltaTime);
			FVector PrevLocAlongSpline = DestinationComp.FollowSplinePosition.WorldLocation;
			DestinationComp.FollowSplinePosition.Move(AccSpeedAlongSpline.Value * DeltaTime);
			Movement.AddDelta(DestinationComp.FollowSplinePosition.WorldLocation - PrevLocAlongSpline);

			MoveDir = DestinationComp.FollowSplinePosition.WorldForwardVector * FollowSign;
		}
		
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * MoveSettings.AirFriction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);
		Movement.AddPendingImpulses();

		if(DestinationComp.Focus.IsValid())
			AccRot.AccelerateTo((DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation).Rotation(), MoveSettings.TurnDuration, DeltaTime);
		else
		{
			FVector CurrentLocation = DestinationComp.FollowSplinePosition.WorldLocation;
			float Add = DestinationComp.bFollowSplineForwards ? 50 : -50;
			FVector AheadLocation = DestinationComp.FollowSpline.GetWorldLocationAtSplineDistance(DestinationComp.FollowSplinePosition.CurrentSplineDistance + Add);
			FVector Direction = AheadLocation - CurrentLocation;
			AccRot.AccelerateTo(Direction.Rotation(), MoveSettings.TurnDuration, DeltaTime);
		}

		Eye.MeshOffsetComponent.SetWorldRotation(FRotator::MakeFromXY(AccRot.Value.ForwardVector, Eye.Boss.ActorForwardVector));
	}

	void CaptureSpline()
	{
		bCapturedSpline = true;	

		FVector SplineDir = DestinationComp.FollowSplinePosition.WorldForwardVector * (DestinationComp.bFollowSplineForwards ? 1 : -1);
		AccSpeedAlongSpline.SnapTo(SplineDir.DotProduct(Owner.ActorVelocity));
		AccCaptureAlpha.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);
		if(HasControl())
			SyncedRotator.Value = Eye.MeshOffsetComponent.WorldRotation;
		else
			Eye.MeshOffsetComponent.WorldRotation = SyncedRotator.Value;
	}
}
