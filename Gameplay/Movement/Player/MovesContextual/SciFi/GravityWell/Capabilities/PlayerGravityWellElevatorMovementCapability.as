
class UPlayerGravityWellElevatorMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::GravityWell);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunMovement);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 19;
	default TickGroupSubPlacement = 6;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 4);

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;	
	UPlayerAimingComponent AimComp;
	UPlayerGravityWellComponent GravityWellComp;

	float CurrentSpeed = 0.0;
	FHazeAcceleratedVector2D AcceleratedPlaneOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		GravityWellComp = UPlayerGravityWellComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGravityWellActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		AGravityWell NearbyGravityWell = GravityWellComp.GetValidNearbyGravityWell();
		if (NearbyGravityWell == nullptr)
			return false;

		if(!NearbyGravityWell.bIsVerticalWell)
			return false;
		
		// Only activate if you are moving towards the well
		FVector SplineLocation = NearbyGravityWell.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorCenterLocation);
		FVector ToSpline = SplineLocation - Player.ActorCenterLocation;
		if (ToSpline.DotProduct(MoveComp.Velocity) < 0.0)
			return false;

		ActivationParams.GravityWell = NearbyGravityWell;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveGravityWell == nullptr)
			return true;

		if (!ActiveGravityWell.bEnabled)
			return true;

		if (!GravityWellComp.Settings.bLockPlayerInsideWell)
		{
			if (!ActiveGravityWell.IsWorldLocationInsideWell(Player.ActorCenterLocation))
				return true;
		}

		if(!ActiveGravityWell.bIsVerticalWell)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerGravityWellActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::GravityWell, this);

		GravityWellComp.ActivateGravityWell(ActivationParams, this);
		GravityWellComp.CurrentState = EPlayerGravityWellState::Movement;

		ActiveGravityWell.ApplySettings(Player, this);
		FSplinePosition SplinePosition = ActiveGravityWell.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);
		GravityWellComp.UpdateDistanceAlongSpline(SplinePosition.CurrentSplineDistance); 
		GravityWellComp.GravityWellMovementDirection = SplinePosition.WorldForwardVector;

		FVector RelativeVelocity = GetRelativeVelocity(MoveComp.Velocity, GravityWellComp.DistanceAlongSpline);
		CurrentSpeed = RelativeVelocity.X;
		
		FVector2D PlaneOffset = GetPlaneOffset(Player.ActorCenterLocation, GravityWellComp.DistanceAlongSpline);
		FVector2D PlaneVelocity = FVector2D(RelativeVelocity.Y, RelativeVelocity.Z);
		AcceleratedPlaneOffset.SnapTo(PlaneOffset, PlaneVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		Player.ClearSettingsByInstigator(this);
		Player.UnblockCapabilities(BlockedWhileIn::GravityWell, this);
		GravityWellComp.ClearGravityWell(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (MoveComp.PrepareMove(Movement))
		{
			// Move to target
			float ToTarget = ActiveGravityWell.ExitTargetDistanceAlongSpline - GravityWellComp.DistanceAlongSpline;
			if (ActiveSpline.IsClosedLoop() && Math::Abs(ToTarget) > ActiveSpline.SplineLength / 2.0)
				ToTarget -= ActiveSpline.SplineLength * Math::Sign(ToTarget);

			CurrentSpeed = Math::FInterpTo(CurrentSpeed, GravityWellComp.Settings.ForwardSpeed * Math::Sign(ToTarget), DeltaTime, GravityWellComp.Settings.ForwardSpeedInterpSpeed);
			float DistanceAlongSpline = GravityWellComp.DistanceAlongSpline;
			float DeltaDistance = CurrentSpeed * DeltaTime;
			if (Math::Abs(ToTarget) <= Math::Abs(DeltaDistance))
				DeltaDistance = ToTarget;
			DistanceAlongSpline += DeltaDistance;

			if (ActiveSpline.IsClosedLoop())
			{
				// Normalize the distance between 0 and max
				if (DistanceAlongSpline < 0.0)
					DistanceAlongSpline += ActiveSpline.SplineLength;
				else if (DistanceAlongSpline > ActiveSpline.SplineLength)
					DistanceAlongSpline -= ActiveSpline.SplineLength;
			}
			else
			{
				// If it isn't looping, you shouldn't exceed the spline length
				if (DistanceAlongSpline < 0.0 || DistanceAlongSpline > ActiveSpline.SplineLength)
				{
					DistanceAlongSpline = Math::Clamp(DistanceAlongSpline, 0.0, ActiveSpline.SplineLength);
					CurrentSpeed = 0.0;
				}
			}

			FVector Forward = ActiveGravityWell.Spline.GetWorldForwardVectorAtSplineDistance(DistanceAlongSpline);
			FVector Right = MoveComp.WorldUp.CrossProduct(Forward).GetSafeNormal();
			Right *= Math::Sign(Player.ControlRotation.RightVector.DotProduct(Right));

			FVector2D MoveInput2D = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			MoveInput2D = FVector2D(MoveInput2D.Y, MoveInput2D.X);

			if (IsActioning(ActionNames::MovementVerticalUp))
				MoveInput2D.Y += 1.0;
			if (IsActioning(ActionNames::MovementVerticalDown))
				MoveInput2D.Y -= 1.0;
	
			MoveInput2D = MoveInput2D.GetClampedToMaxSize(1.0);

			FVector MoveInput = ((MoveComp.WorldUp * MoveInput2D.Y) + (Right * MoveInput2D.X)).GetClampedToMaxSize(1.0);
			FRotator SplineRotation = ActiveGravityWell.Spline.GetWorldRotationAtSplineDistance(DistanceAlongSpline).Rotator();
			MoveInput = SplineRotation.UnrotateVector(MoveInput);
			MoveInput2D = FVector2D(MoveInput.Y, MoveInput.Z);

			AcceleratedPlaneOffset.Velocity += MoveInput2D * GravityWellComp.Settings.PlayerPlaneMoveSpeed * DeltaTime;
			
			// Pull to center
			if (MoveInput2D.IsNearlyZero())
				AcceleratedPlaneOffset.SpringTo(FVector2D::ZeroVector, GravityWellComp.Settings.PullToCenterStrength, 1.0, DeltaTime);
			else
			{
				AcceleratedPlaneOffset.Velocity -= AcceleratedPlaneOffset.Velocity * 1.8 * DeltaTime;
				AcceleratedPlaneOffset.SpringTo(FVector2D::ZeroVector, 0.0, 0.8, DeltaTime);
			}
	
			// Clamp to the radius
			const float ClampRadius = Math::Clamp(GravityWellComp.Settings.Radius - GravityWellComp.Settings.LockPlayerMargin, 0.0, GravityWellComp.Settings.Radius);
			const bool bTravellingOutwards = AcceleratedPlaneOffset.Value.DotProduct(AcceleratedPlaneOffset.Velocity) >= 0.0;
			if (GravityWellComp.Settings.bLockPlayerInsideWell &&
				bTravellingOutwards &&
				AcceleratedPlaneOffset.Value.Size() > ClampRadius)
			{
				float OutwardsVelocity = AcceleratedPlaneOffset.Velocity.DotProduct(AcceleratedPlaneOffset.Value.GetSafeNormal());

				AcceleratedPlaneOffset.Value = AcceleratedPlaneOffset.Value.GetSafeNormal() * ClampRadius;
				AcceleratedPlaneOffset.Velocity -= AcceleratedPlaneOffset.Value.GetSafeNormal() * OutwardsVelocity;
			}

			FVector NewLocation = GetWorldLocationWithOffsetAtDistanceAlongSpline(AcceleratedPlaneOffset.Value, DistanceAlongSpline);			
			FVector DeltaMove = NewLocation - Player.ActorCenterLocation;
			Movement.AddDelta(DeltaMove);

			FVector ForwardLookDir = Player.GetControlRotation().ForwardVector;
			ForwardLookDir = ForwardLookDir.VectorPlaneProject(MoveComp.WorldUp);
			if(ForwardLookDir.IsNearlyZero())
				ForwardLookDir = Player.ActorForwardVector;
				
			
			FRotator TargetRotation = FRotator::MakeFromXZ(ForwardLookDir, MoveComp.WorldUp);
			Movement.SetRotation(Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, AimComp.IsAiming() ? 10.0 : 3.0));

			// Removed for now
			// if (GravityWellComp.Settings.bRotatePlayerInWellMovement)
			// {
			// 	FVector SplineDirection = ActiveSpline.GetWorldForwardVectorAtSplineDistance(GravityWellComp.DistanceAlongSpline);
			// 	SplineDirection *= Math::Sign(ToTarget);

			// 	FRotator TargetRotation = FRotator::MakeFromXZ(SplineDirection, MoveComp.WorldUp);
			// 	if (!Math::IsNearlyEqual(TargetRotation.ForwardVector.DotProduct(MoveComp.WorldUp), 1.0))
			// 	{
			// 		TargetRotation.Pitch = 0.0;
			// 		Movement.SetRotation(Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, 3.0));
			// 	}
			// }

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"GravityWell");

			// Finalize the distance along the spline depending on how far we could move
			FSplinePosition SplinePosition = ActiveGravityWell.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);
			GravityWellComp.UpdateDistanceAlongSpline(SplinePosition.CurrentSplineDistance); 
			GravityWellComp.GravityWellMovementDirection = SplinePosition.WorldForwardVector;
		}
	}

	AGravityWell GetActiveGravityWell() const property
	{
		return GravityWellComp.ActiveGravityWell;
	}

	UHazeSplineComponent GetActiveSpline() const property
	{
		return GravityWellComp.ActiveGravityWell.Spline;
	}

	FVector GetRelativeVelocity(FVector Velocity, float DistanceAlongSpline)
	{
		return GravityWellComp.ActiveGravityWell.Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline).InverseTransformVectorNoScale(Velocity);
	}

	FVector2D GetPlaneOffset(FVector WorldLocation, float DistanceAlongSpline)
	{
		FTransform Transform = GravityWellComp.ActiveGravityWell.Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector ToPlayer = WorldLocation - Transform.Location;
		FVector Offset = Transform.InverseTransformVectorNoScale(ToPlayer);

		return FVector2D(Offset.Y, Offset.Z);
	}

	FVector GetWorldLocationWithOffsetAtDistanceAlongSpline(FVector2D Offset, float DistanceAlongSpline)
	{
		FTransform Transform = GravityWellComp.ActiveGravityWell.Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector WorldOffset = Transform.TransformVectorNoScale(FVector(0.0, Offset.X, Offset.Y));
		return Transform.Location + WorldOffset;
	}
}
