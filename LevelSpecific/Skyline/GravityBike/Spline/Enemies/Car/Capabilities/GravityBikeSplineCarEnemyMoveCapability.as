struct FGravityBikeSplineCarEnemyMoveDeactivateParams
{
	bool bExplode = false;
};

class UGravityBikeSplineCarEnemyMoveCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	AGravityBikeSplineCarEnemy CarEnemy;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UHazeMovementComponent MoveComp;
	UGravityBikeSplineFlyingEnemyMovementData MoveData;

	bool bShouldExplode = false;

	FHazeAcceleratedQuat AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<AGravityBikeSplineCarEnemy>(Owner);
		SplineMoveComp = CarEnemy.SplineMoveComp;
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);

		MoveComp = CarEnemy.MoveComp;
		MoveData = MoveComp.SetupMovementData(UGravityBikeSplineFlyingEnemyMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(HealthComp.IsDead())
			return false;

		if(HealthComp.IsRespawning())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineCarEnemyMoveDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(HealthComp.IsDead())
			return true;

		if(HealthComp.IsRespawning())
			return true;

		if(bShouldExplode)
		{
			Params.bExplode = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CarEnemy.State = EGravityBikeSplineCarEnemyState::Default;

		SplineMoveComp.SnapSpeed();
		const FTransform NewSplineTransform = SplineMoveComp.GetSplineTransform();
		CarEnemy.SetActorVelocity(NewSplineTransform.Rotation.ForwardVector * SplineMoveComp.Speed);

		bShouldExplode = false;

		AccRotation.SnapTo(CarEnemy.ActorQuat);
		CarEnemy.AccMeshRotation.SnapTo(FQuat::Identity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineCarEnemyMoveDeactivateParams Params)
	{
		if(Params.bExplode)
		{
			HealthComp.bExplode = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		CarEnemy.LightsRotationPivot.AddRelativeRotation(FRotator(0.0, CarEnemy.LightsRotationSpeed * DeltaTime, 0.0));
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

		const FTransform NewSplineTransform = SplineMoveComp.GetSplineTransform();

		// FVector RelativeLocation = NewSplineTransform.InverseTransformPositionNoScale(CarEnemy.ActorLocation);
		// RelativeLocation.X = 0;
		// FVector TargetLocation = NewSplineTransform.TransformPositionNoScale(RelativeLocation);

		FHazeAcceleratedVector AccLocation;
		AccLocation.SnapTo(CarEnemy.ActorLocation, CarEnemy.ActorVelocity);

		float LocationStiffness;
		float LocationDamping;
		GetLocationSpringValues(LocationStiffness, LocationDamping);

		AccLocation.SpringTo(
			NewSplineTransform.Location,
			LocationStiffness,
			LocationDamping,
			DeltaTime
		);

		AccRotation.SpringTo(
			NewSplineTransform.Rotation,
			GravityBikeSpline::CarEnemy::RotationStiffness,
			GravityBikeSpline::CarEnemy::RotationDamping,
			DeltaTime
		);

		MoveData.AddDeltaFromMoveTo(AccLocation.Value);

		MoveData.SetRotation(AccRotation.Value);

		MoveData.AddPendingImpulses();
		
#if !RELEASE
		TEMPORAL_LOG(this)
			.Transform("NewSplineTransform", NewSplineTransform, 500, 10)
			.Arrow("To Final Transform", NewSplineTransform.Location, AccLocation.Value, 10)
			.Transform("Final Transform", FTransform(AccRotation.Value, AccLocation.Value), 500, 10)
			.Point("AccLocation;Value", AccLocation.Value)
			.DirectionalArrow("AccLocation;Velocity", AccLocation.Value, AccLocation.Velocity)
			.DirectionalArrow("AccLocation;Velocity", AccLocation.Value, AccLocation.Velocity)
			.Value("AccLocation;LocationStiffness", LocationStiffness)
			.Value("AccLocation;LocationDamping", LocationDamping)
		;
#endif
	}

	/**
	 * Visual mesh rotation. Applied separately on both Control and Remote
	 */
	void TickMeshRotation(float DeltaTime)
	{
		FVector Jolt = (MoveComp.Velocity - MoveComp.PreviousVelocity);

		{
			const FTransform SplineTransform = SplineMoveComp.GetSplineTransform();
			FVector JoltAlongSpline = Jolt.ProjectOnToNormal(SplineTransform.Rotation.ForwardVector);
			FVector HorizontalJolt = Jolt - JoltAlongSpline;
			JoltAlongSpline *= GravityBikeSpline::CarEnemy::MeshRotationJoltAlongSplineMultiplier;
			HorizontalJolt *= GravityBikeSpline::CarEnemy::MeshRotationHorizontalJoltSplineMultiplier;

			Jolt = JoltAlongSpline + HorizontalJolt;
		}

		const FVector SplineUpVector = SplineMoveComp.EnemySpline.GetUpAtSplineDistance(SplineMoveComp.GetDistanceAlongSpline());
		FVector WorldAngularImpulse = SplineUpVector.CrossProduct(Jolt);

		const FVector RelativeAngularImpulse = CarEnemy.ActorTransform.InverseTransformVectorNoScale(WorldAngularImpulse);

		float AngularImpulseMagnitude = RelativeAngularImpulse.Size() * GravityBikeSpline::CarEnemy::MeshRotationJoltMultiplier;

		const float Limit = Math::DegreesToRadians(GravityBikeSpline::CarEnemy::MeshRotationAngleLimit);
		AngularImpulseMagnitude = Math::Clamp(AngularImpulseMagnitude, -Limit, Limit);

		const FQuat TargetRotation = FQuat(RelativeAngularImpulse.GetSafeNormal(), AngularImpulseMagnitude);

		//Debug::DrawDebugCoordinateSystem(CarEnemy.ActorLocation, CarEnemy.ActorTransform.TransformRotation(TargetRotation.Rotator()), 500, 10);

		CarEnemy.AccMeshRotation.SpringTo(
			TargetRotation,
			GravityBikeSpline::CarEnemy::MeshRotationStiffness,
			GravityBikeSpline::CarEnemy::MeshRotationDamping,
			DeltaTime
		);

		const FQuat RelativeRotation = GravityBikeSpline::CarEnemy::RotationOffset * CarEnemy.AccMeshRotation.Value;

		CarEnemy.MeshPivot.SetRelativeRotation(RelativeRotation);
	}

	void GetLocationSpringValues(float&out OutStiffness, float&out OutDamping) const
	{
		OutStiffness = GravityBikeSpline::CarEnemy::LocationStiffness;
		OutDamping = GravityBikeSpline::CarEnemy::LocationDamping;
		
		if(WasRecentlyDamagedWithImpulse())
		{
			OutStiffness *= 0.5;
			OutDamping *= 0.5;
		}
		else if(WasRecentlyReflectedOffWall())
		{
			OutStiffness *= 0.2;
			OutDamping *= 0.2;
		}
	}

	bool WasRecentlyDamagedWithImpulse() const
	{
		if(CarEnemy.DamageImpulseTime < 0)
			return false;

		return Time::GetGameTimeSince(CarEnemy.DamageImpulseTime) < 2;
	}

	bool WasRecentlyReflectedOffWall() const
	{
		if(CarEnemy.ReflectOffWallTime < 0)
			return false;

		return Time::GetGameTimeSince(CarEnemy.ReflectOffWallTime) < 1;
	}
};