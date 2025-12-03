
class UPlayerGravityWellTubeMovementCapability : UHazePlayerCapability
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
	UGravityWellMovementData Movement;	
	UPlayerAimingComponent AimComp;
	UPlayerGravityWellComponent GravityWellComp;

	//float CurrentSpeed = 0.0;
	//FSplinePosition CurrentSplinePosition;
	//float CurrentOffsetSpeed = 0.0;
	bool bIsInsideSpline = false;
	FSplinePosition PrevPosition;
	FRotator PrevSplineOrientation;
	FVector PlaneOffset = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		GravityWellComp = UPlayerGravityWellComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UGravityWellMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGravityWellActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		AGravityWell NearbyGravityWell = GravityWellComp.GetValidNearbyGravityWell();
		if (NearbyGravityWell == nullptr)
			return false;

		if(NearbyGravityWell.bIsVerticalWell)
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

		if(ActiveGravityWell.bIsVerticalWell)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerGravityWellActivationParams ActivationParams)
	{
		MoveComp.OverrideResolver(UGravityWellMovementResolver, this, EInstigatePriority::Normal);
		Player.BlockCapabilities(BlockedWhileIn::GravityWell, this);

		GravityWellComp.ActivateGravityWell(ActivationParams, this);
		GravityWellComp.CurrentState = EPlayerGravityWellState::Movement;

		ActiveGravityWell.ApplySettings(Player, this);
		PrevPosition = ActiveGravityWell.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);
		GravityWellComp.UpdateDistanceAlongSpline(PrevPosition.CurrentSplineDistance); 
		GravityWellComp.GravityWellMovementDirection = PrevPosition.WorldForwardVector;

		if(PrevPosition.WorldForwardVector.DotProduct(FVector::UpVector) > 1.0 - KINDA_SMALL_NUMBER)
			PrevSplineOrientation = FRotator::MakeFromXZ(PrevPosition.WorldForwardVector, FVector::RightVector);
		else
			PrevSplineOrientation = FRotator::MakeFromXZ(PrevPosition.WorldForwardVector, FVector::UpVector);

		PlaneOffset = Player.ActorCenterLocation - PrevPosition.WorldLocation;
		//PlaneOffset = PrevSplineOrientation.UnrotateVector(Offset);

		//PlaneOffset = PrevPosition.WorldTransform.InverseTransformVectorNoScale(Player.ActorCenterLocation);

		// FRotator SplineOrientation;
		// if(GravityWellComp.GravityWellMovementDirection.DotProduct(MoveComp.WorldUp) > 1.0 - KINDA_SMALL_NUMBER)
		// 	SplineOrientation = FRotator::MakeFromXZ(GravityWellComp.GravityWellMovementDirection, Player.ActorForwardVector);
		// else
		// 	SplineOrientation = FRotator::MakeFromXZ(GravityWellComp.GravityWellMovementDirection, MoveComp.WorldUp);

		//FVector PlaneVelocity = MoveComp.Velocity.VectorPlaneProject(SplineOrientation.UpVector);
		// CurrentSpeed = Math::Max(PlaneVelocity.DotProduct(GravityWellComp.GravityWellMovementDirection), 0.0);
		// CurrentOffsetSpeed = 0.0;

		const float DistanceToSplineCenterSq = PrevPosition.WorldLocation.DistSquared(Player.ActorLocation);
		const float MaxDista = GravityWellComp.Settings.Radius - GravityWellComp.Settings.LockPlayerMargin;
		bIsInsideSpline = DistanceToSplineCenterSq < Math::Square(MaxDista);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		MoveComp.ClearResolverOverride(UGravityWellMovementResolver, this);
		Player.ClearSettingsByInstigator(this);
		Player.UnblockCapabilities(BlockedWhileIn::GravityWell, this);
		GravityWellComp.ClearGravityWell(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (MoveComp.PrepareMove(Movement))
		{
			// Init the movement data
			Movement.CurrentSplinePosition = ActiveGravityWell.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);
			Movement.MaxDistance = GravityWellComp.Settings.Radius - GravityWellComp.Settings.LockPlayerMargin;

			float CurrentSpeed = MoveComp.HorizontalVelocity.Size();
			CurrentSpeed = Math::FInterpTo(CurrentSpeed, GravityWellComp.Settings.ForwardSpeed, DeltaTime, GravityWellComp.Settings.ForwardSpeedInterpSpeed);

			Movement.CurrentSplinePosition.Move(CurrentSpeed * DeltaTime);

			// Set rotation
			FRotator TargetRotation = FRotator::ZeroRotator;
			{
				FVector ForwardLookDir = Player.GetControlRotation().ForwardVector;
				ForwardLookDir = ForwardLookDir.VectorPlaneProject(MoveComp.WorldUp);
				if(ForwardLookDir.IsNearlyZero())
					ForwardLookDir = Player.ActorForwardVector;
				
				TargetRotation = FRotator::MakeFromXZ(ForwardLookDir, MoveComp.WorldUp);
				Movement.SetRotation(Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, AimComp.IsAiming() ? 10.0 : 3.0));
			}

			const float MaxCenterOffset = GravityWellComp.Settings.Radius - GravityWellComp.Settings.LockPlayerMargin;
			const float VerticalAmount = Movement.CurrentSplinePosition.WorldForwardVector.DotProductLinear(MoveComp.WorldUp);
			const bool bMovingHorizontally = VerticalAmount < 0.7;
			
			const FVector SplineDeltaMove = Movement.CurrentSplinePosition.WorldLocation - PrevPosition.WorldLocation;	
			const FVector PendingActorCenterLocation = Player.ActorCenterLocation + SplineDeltaMove;
			const FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);		
			const FVector PreviousPlaneOffset = PlaneOffset;

			if(bMovingHorizontally)
			{
				const FRotator SplineOrientation = FRotator::MakeFromXZ(Movement.CurrentSplinePosition.WorldForwardVector, MoveComp.WorldUp);
				const FVector Forward = SplineOrientation.ForwardVector;
				const FVector Right = SplineOrientation.RightVector;
				
				const float ForwardIsForward = Forward.DotProductLinear(Player.ControlRotation.ForwardVector.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal()) * Math::Sign(Forward.DotProduct(Player.ControlRotation.ForwardVector));

				// Convert the input into spline space
				FVector Input = FVector::ZeroVector;
				Input += (MoveComp.WorldUp * RawStick.X);
				Input += (Right * RawStick.Y * ForwardIsForward);

				// Generate the plane offset movement speed
				const FVector DirToCenter = (Movement.CurrentSplinePosition.WorldLocation - PendingActorCenterLocation).GetSafeNormal();
				const float InputTowardCenter = Input.GetSafeNormal().DotProductNormalized(DirToCenter);
				const float DistanceToCenterAlpha = Math::Min(PendingActorCenterLocation.Distance(Movement.CurrentSplinePosition.WorldLocation) / MaxCenterOffset, 1.0);
				float DistanceSpeed = Math::Lerp(GravityWellComp.Settings.PlayerPlaneMoveSpeed, 0.0, DistanceToCenterAlpha);
				DistanceSpeed = Math::Lerp(DistanceSpeed, GravityWellComp.Settings.PlayerPlaneMoveSpeed, Math::Pow(InputTowardCenter, 2.0));

				float OffsetSpeed = MoveComp.VerticalVelocity.Size();
				if(!Input.IsNearlyZero())
					OffsetSpeed = Math::FInterpTo(OffsetSpeed, DistanceSpeed, DeltaTime, 5.0);
				else
					OffsetSpeed = Math::FInterpTo(OffsetSpeed, 0.0, DeltaTime, 10.0);

				// Offset the vertical plane from the input
				PlaneOffset += Input * OffsetSpeed * DeltaTime;
				PlaneOffset = PlaneOffset.GetClampedToMaxSize(MaxCenterOffset - 1);

				if(Input.IsNearlyZero() && GravityWellComp.Settings.PullToCenterStrength > 0)
					PlaneOffset = Math::VInterpTo(PlaneOffset, FVector::ZeroVector, DeltaTime, GravityWellComp.Settings.PullToCenterStrength);

				const FVector PreviousOffset = Movement.CurrentSplinePosition.WorldLocation + PreviousPlaneOffset;
				const FVector Offset = Movement.CurrentSplinePosition.WorldLocation + PlaneOffset;

				Movement.AddHorizontalDelta(SplineDeltaMove);
				Movement.AddVerticalDelta(Offset - PreviousOffset);	

				PrevSplineOrientation = SplineOrientation;	
			}
			else
			{
				const FRotator SplineOrientation = FRotator::MakeFromXZ(Movement.CurrentSplinePosition.WorldForwardVector, FVector::RightVector);
				
				FVector Input = FVector::ZeroVector;
				Input += (Player.ControlRotation.ForwardVector.VectorPlaneProject(Movement.CurrentSplinePosition.WorldForwardVector) * RawStick.X);
				Input += (Player.ControlRotation.RightVector * RawStick.Y);

				// Generate the plane offset movement speed
				const FVector DirToCenter = (Movement.CurrentSplinePosition.WorldLocation - PendingActorCenterLocation).GetSafeNormal();
				const float InputTowardCenter = Input.GetSafeNormal().DotProductNormalized(DirToCenter);
				const float DistanceToCenterAlpha = Math::Min(PendingActorCenterLocation.Distance(Movement.CurrentSplinePosition.WorldLocation) / MaxCenterOffset, 1.0);
				float DistanceSpeed = Math::Lerp(GravityWellComp.Settings.PlayerPlaneMoveSpeed, 0.0, DistanceToCenterAlpha);
				DistanceSpeed = Math::Lerp(DistanceSpeed, GravityWellComp.Settings.PlayerPlaneMoveSpeed, Math::Pow(InputTowardCenter, 2.0));

				float OffsetSpeed = MoveComp.VerticalVelocity.Size();
				if(!Input.IsNearlyZero())
					OffsetSpeed = Math::FInterpTo(OffsetSpeed, DistanceSpeed, DeltaTime, 5.0);
				else
					OffsetSpeed = Math::FInterpTo(OffsetSpeed, 0.0, DeltaTime, 10.0);	

				// Offset the horizontal plane from the spline center
				PlaneOffset += Input * OffsetSpeed * DeltaTime;
				PlaneOffset = PlaneOffset.GetClampedToMaxSize(MaxCenterOffset - 1);

				if(Input.IsNearlyZero() && GravityWellComp.Settings.PullToCenterStrength > 0)
					PlaneOffset = Math::VInterpTo(PlaneOffset, FVector::ZeroVector, DeltaTime, GravityWellComp.Settings.PullToCenterStrength);

				const FVector PreviousOffset = Movement.CurrentSplinePosition.WorldLocation + PreviousPlaneOffset;
				const FVector Offset = Movement.CurrentSplinePosition.WorldLocation + PlaneOffset;

				Movement.AddHorizontalDelta(SplineDeltaMove);
				Movement.AddVerticalDelta(Offset - PreviousOffset);		

				PrevSplineOrientation = SplineOrientation;	
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"GravityWell");

			// Finalize the distance along the spline depending on how far we could move
			{
				PrevPosition = ActiveGravityWell.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);

				FRotator SplineOrientation;
				if(PrevPosition.WorldForwardVector.DotProduct(FVector::UpVector) > 1.0 - KINDA_SMALL_NUMBER)
					SplineOrientation = FRotator::MakeFromXZ(PrevPosition.WorldForwardVector, FVector::RightVector);
				else
					SplineOrientation = FRotator::MakeFromXZ(PrevPosition.WorldForwardVector, FVector::UpVector);

				const float DistanceToSplineCenterSq = PrevPosition.WorldLocation.DistSquared(Player.ActorLocation);
				const float MaxDist = GravityWellComp.Settings.Radius - GravityWellComp.Settings.LockPlayerMargin;
				bIsInsideSpline = DistanceToSplineCenterSq < Math::Square(MaxDist);
				GravityWellComp.UpdateDistanceAlongSpline(PrevPosition.CurrentSplineDistance); 
				GravityWellComp.GravityWellMovementDirection = PrevPosition.WorldForwardVector;
			}
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
	
}

