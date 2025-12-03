struct FTundraWalkToBirdDeactivationParams
{
	bool bWasCanceled = false;
}

class UTundraPlayerWalkToCrackBirdTargetCapability : UTundraPlayerCrackBirdBaseCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	FHazeRuntimeSpline NavigationSpline;
	bool bUsingNavPoint;
	float DistanceAlongSpline;
	const float MoveSpeed = 560;

	float ReachTargetRange;
 	const ABigCrackBirdNest Nest;
	UTundraPlayerShapeshiftingComponent ShapeshiftComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.HasGroundContact())
			return false;

		const ETundraPlayerCrackBirdState State = CarryComp.GetCurrentState();
		if(State != ETundraPlayerCrackBirdState::WalkingToBird && State != ETundraPlayerCrackBirdState::WalkingToNest)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundraWalkToBirdDeactivationParams& Params) const
	{
		if(IsInRange() && IsLookingAtNest())
			return true;

		if(ShapeshiftComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
			return true;

		if(CarryComp.GetCurrentState() == ETundraPlayerCrackBirdState::WalkingToBird)
		{
			if(CarryComp.GetBird().IsBeingLaunched())
			{
				Params.bWasCanceled = true;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Nest = CarryComp.GetTargetNest();
		if(Nest == nullptr)
			Nest = CarryComp.GetBird().CurrentNest;

		check(Nest != nullptr);

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);

		bUsingNavPoint = Nest.bUseNavPoint;
		DistanceAlongSpline = 0;
		ReachTargetRange = Nest.DistToPickupBird;

		const float HorizontalDistanceToNest = Nest.ActorLocation.DistXY(Player.ActorLocation);
		FVector Target = Nest.ActorLocation + (Player.ActorLocation - Nest.ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal() * ReachTargetRange;
		
		if(HorizontalDistanceToNest <= ReachTargetRange && HorizontalDistanceToNest > ReachTargetRange * 0.8)
		{
			Target = Player.ActorLocation;
		}

		const UNavigationPath Path;
		if(bUsingNavPoint)
			Path = UNavigationSystemV1::FindPathToLocationSynchronously(Owner.ActorLocation, Nest.NavPoint.WorldLocation);
		else
		{
			Path = UNavigationSystemV1::FindPathToLocationSynchronously(Owner.ActorLocation, Target);
		}
		
		if(Path == nullptr || !Path.IsValid() || Path.IsPartial())
		{
			TArray<FVector> Points;
			Points.Add(Owner.ActorLocation);

			if(HorizontalDistanceToNest <= ReachTargetRange * 0.8)
			{
				FVector NearestEdgeOfNestOffset = Nest.ActorLocation + (Player.ActorLocation - Nest.ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal() * ReachTargetRange * 1.2;
				Points.Add(NearestEdgeOfNestOffset);
			}

			Points.Add(Target);
			NavigationSpline.SetPoints(Points);
		}
		else
		{
			TArray<FVector> PathPoints = Path.PathPoints;
			
			if(Nest.bUseNavPoint)
				PathPoints.Add(Nest.ActorLocation + (Nest.NavPoint.WorldLocation - Nest.ActorLocation).GetSafeNormal() * ReachTargetRange);

			NavigationSpline.SetPoints(PathPoints);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundraWalkToBirdDeactivationParams Params)
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.ClearMovementInput(this);

		if(Params.bWasCanceled)
		{
			CarryComp.CancelPickingUp();
			return;
		}

		if(ShapeshiftComp.GetCurrentShapeType() == ETundraShapeshiftShape::Big)
			CarryComp.TargetReached();
		else
			CarryComp.CancelPickingUp();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//NavigationSpline.DrawDebugSpline();
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				DistanceAlongSpline += DeltaTime * MoveSpeed;
				FVector Location = NavigationSpline.GetLocationAtDistance(DistanceAlongSpline);
				FVector Delta = Location - Owner.ActorLocation;
				FVector Direction = Delta.GetSafeNormal();
				if(DistanceAlongSpline >= NavigationSpline.Length)
				Direction = (Nest.ActorLocation - Player.ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();

				if(!IsInRange())
					Movement.AddDelta(Delta, EMovementDeltaType::HorizontalExclusive);

				Player.ApplyMovementInput(Delta.GetSafeNormal(), this);
				Movement.InterpRotationTo(Direction.ToOrientationQuat(), 5);
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			if(CarryComp.GetCurrentState() == ETundraPlayerCrackBirdState::WalkingToNest)
			{
				if(GetBird().bIsEgg)
				{
					MoveComp.ApplyMoveAndRequestLocomotion(Movement,  n"PickupBirdEgg");
				}
				else
				{
					MoveComp.ApplyMoveAndRequestLocomotion(Movement,  n"PickupBird");
				}
			}
			else
				MoveComp.ApplyMoveAndRequestLocomotion(Movement,  n"Movement");
		}
	}

	bool IsLookingAtNest() const
	{
		FVector ToNest = Nest.ActorLocation - Owner.ActorLocation;
		float Dot = Player.ActorForwardVector.DotProduct(ToNest.VectorPlaneProject(FVector::UpVector).GetSafeNormal());
		return Dot >= 0.99;
	}

	bool IsInRange() const
	{
		return DistanceAlongSpline >= NavigationSpline.Length;
	}
};