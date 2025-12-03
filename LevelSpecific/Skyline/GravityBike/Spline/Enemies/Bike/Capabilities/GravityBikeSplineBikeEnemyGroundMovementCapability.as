struct FGravityBikeSplineBikeEnemyGroundMovementActivateParams
{
	EGravityBikeSplineBikeEnemyMovementState PreviousMovementState;
};

class UGravityBikeSplineBikeEnemyGroundMovementCapability : UHazeCapability
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

	bool bPitchBounced = false;

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
	bool ShouldActivate(FGravityBikeSplineBikeEnemyGroundMovementActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsInAir())
			return false;

		if(BikeEnemy.State != EGravityBikeSplineBikeEnemyState::Default)
			return false;

		if(HealthComp.IsDead())
			return false;

		if(HealthComp.bExplode)
			return false;

		Params.PreviousMovementState = BikeEnemy.MovementState;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsInAir())
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
	void OnActivated(FGravityBikeSplineBikeEnemyGroundMovementActivateParams Params)
	{
		SplineMoveComp.SnapSplinePositionToClosest(BikeEnemy.ActorLocation, 0);

		const FTransform SplineTransform = SplineMoveComp.GetSplineTransform();

		const FVector InitialHorizontalLocation = BikeEnemy.OffsetComp.WorldLocation.VectorPlaneProject(MoveComp.WorldUp);
		const FVector HorizontalLocation = SplineTransform.Location.VectorPlaneProject(MoveComp.WorldUp);

		FVector Offset = InitialHorizontalLocation - HorizontalLocation;
		Offset = BikeEnemy.OffsetComp.AttachParent.WorldTransform.InverseTransformVectorNoScale(Offset);
		BikeEnemy.OffsetComp.ClearOffset(this);
		BikeEnemy.OffsetComp.SnapToRelativeLocation(this, BikeEnemy.OffsetComp.AttachParent, Offset);
		BikeEnemy.OffsetComp.ResetOffsetWithMinSpeed(this, 250);

		switch(Params.PreviousMovementState)
		{
			case EGravityBikeSplineBikeEnemyMovementState::None:
				SplineMoveComp.Speed = SplineMoveComp.MinimumSpeed;
				break;

			case EGravityBikeSplineBikeEnemyMovementState::Ground:
				break;
				
			case EGravityBikeSplineBikeEnemyMovementState::Air:
			case EGravityBikeSplineBikeEnemyMovementState::Drop:
				SplineMoveComp.Speed = MoveComp.HorizontalVelocity.DotProduct(SplineMoveComp.GetSplineTransform().Rotation.ForwardVector);
				UGravityBikeSplineBikeEnemyEventHandler::Trigger_OnGroundImpact(BikeEnemy);
				break;
		}

		BikeEnemy.MovementState = EGravityBikeSplineBikeEnemyMovementState::Ground;
		BikeEnemy.SplineMoveComp.ThrottleWhenPlayerDead.Apply(0.2, this);

		bPitchBounced = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BikeEnemy.SplineMoveComp.ThrottleWhenPlayerDead.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		TickMovement(DeltaTime);

		MoveComp.ApplyMove(MoveData);

		TickMeshRotation(DeltaTime);
	}

	void TickMovement(float DeltaTime)
	{
		SplineMoveComp.MoveSplinePositionForward(DeltaTime);

		const FVector CurrentHorizontalLocation = BikeEnemy.ActorLocation.VectorPlaneProject(MoveComp.WorldUp); 

		const FTransform SplineTransform = SplineMoveComp.GetSplineTransform();
		FVector TargetHorizontalLocation = SplineTransform.Location.VectorPlaneProject(MoveComp.WorldUp);

		FVector HorizontalDelta = TargetHorizontalLocation - CurrentHorizontalLocation;

		MoveData.AddDelta(HorizontalDelta);

		MoveData.AddOwnerVerticalVelocity();
		MoveData.AddGravityAcceleration();

		MoveData.ApplySplineLock();
		MoveData.UseGroundStickynessDistanceThisFrame(5);

		const FQuat TargetRotation = FQuat::MakeFromXZ(SplineTransform.Rotation.ForwardVector, FVector::UpVector);
		MoveData.InterpRotationTo(TargetRotation, 5);
	}

	void TickMeshRotation(float DeltaTime)
	{
		if(BikeEnemy.AccPitch.Value > KINDA_SMALL_NUMBER)
			BikeEnemy.AccPitch.SpringTo(0, 100, 0.1, DeltaTime);
		
		if(BikeEnemy.AccPitch.Value < 0)
		{
			if(!bPitchBounced)
			{
				BikeEnemy.AccPitch.SnapTo(BikeEnemy.AccPitch.Value * -0.5, BikeEnemy.AccPitch.Velocity * -0.5);
			}
			else
			{
				BikeEnemy.AccPitch.SnapTo(0);
			}
		}

		BikeEnemy.RollFromAngularSpeed(DeltaTime);
		BikeEnemy.ApplyMeshPivotRotation();
	}
};