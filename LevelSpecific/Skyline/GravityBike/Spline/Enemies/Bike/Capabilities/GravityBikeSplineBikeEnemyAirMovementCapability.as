struct FGravityBikeSplineBikeEnemyAirMovementActivateParams
{
	EGravityBikeSplineBikeEnemyMovementState PreviousMovementState;
};

class UGravityBikeSplineBikeEnemyAirMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	AGravityBikeSplineBikeEnemy BikeEnemy;
	UHazeMovementComponent MoveComp;
	UGravityBikeSplineBikeEnemyMovementData MoveData;

	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(Owner);
		MoveComp = BikeEnemy.MoveComp;
		MoveData = MoveComp.SetupMovementData(UGravityBikeSplineBikeEnemyMovementData);

		SplineMoveComp = BikeEnemy.SplineMoveComp;
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineBikeEnemyAirMovementActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsInAir())
			return false;

		if(BikeEnemy.State != EGravityBikeSplineBikeEnemyState::Default)
			return false;

		if(HealthComp.IsDead())
			return false;

		if(HealthComp.bExplode)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.IsInAir())
			return true;

		if(BikeEnemy.State != EGravityBikeSplineBikeEnemyState::Default)
			return true;

		if(HealthComp.IsDead())
			return true;

		if(HealthComp.bExplode)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineBikeEnemyAirMovementActivateParams Params)
	{
		switch(Params.PreviousMovementState)
		{
			case EGravityBikeSplineBikeEnemyMovementState::None:
			case EGravityBikeSplineBikeEnemyMovementState::Drop:
				break;
				
			case EGravityBikeSplineBikeEnemyMovementState::Ground:
				UGravityBikeSplineBikeEnemyEventHandler::Trigger_OnJump(BikeEnemy);
				break;

			case EGravityBikeSplineBikeEnemyMovementState::Air:
				break;
		}

		BikeEnemy.MovementState = EGravityBikeSplineBikeEnemyMovementState::Air;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		TickMovement(DeltaTime);

		MoveComp.ApplyMove(MoveData);

		BikeEnemy.AccPitch.AccelerateTo(0, 1, DeltaTime);
		BikeEnemy.RollFromAngularSpeed(DeltaTime);

		BikeEnemy.ApplyMeshPivotRotation();
	}

	void TickMovement(float DeltaTime)
	{
		SplineMoveComp.MoveSplinePositionForward(DeltaTime);

		const FTransform SplineTransform = SplineMoveComp.GetSplineTransform();

		if(SplineMoveComp.HasPassedSplineEnd())
		{
			MoveData.AddOwnerVelocity();
			MoveData.AddGravityAcceleration();
		}
		else
		{
			const FVector HorizontalLocation = BikeEnemy.ActorLocation.VectorPlaneProject(MoveComp.WorldUp);
			const FVector TargetHorizontalLocation = SplineTransform.Location.VectorPlaneProject(MoveComp.WorldUp);
			const FVector HorizontalDelta = TargetHorizontalLocation - HorizontalLocation;
			
			MoveData.AddHorizontalVelocity(HorizontalDelta / DeltaTime);
			
			MoveData.AddOwnerVerticalVelocity();
			MoveData.AddGravityAcceleration();
			MoveData.ApplySplineLock();
		}

		if(!MoveComp.Velocity.IsNearlyZero())
		{
			const FQuat TargetRotation = FQuat::MakeFromXZ(MoveComp.Velocity, FVector::UpVector);
			MoveData.InterpRotationTo(TargetRotation,5);
		}
	}
};