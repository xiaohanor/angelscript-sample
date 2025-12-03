struct FGravityBikeSplineAttackShipMoveDeactivateParams
{
	bool bExplode = false;
};

class UGravityBikeSplineAttackShipMoveCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	AGravityBikeSplineAttackShip AttackShip;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UHazeMovementComponent MoveComp;
	UGravityBikeSplineFlyingEnemyMovementData MoveData;

	bool bShouldExplode = false;

	FHazeAcceleratedQuat AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<AGravityBikeSplineAttackShip>(Owner);
		SplineMoveComp = AttackShip.SplineMoveComp;
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);

		MoveComp = AttackShip.MoveComp;
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
	bool ShouldDeactivate(FGravityBikeSplineAttackShipMoveDeactivateParams& Params) const
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
		AttackShip.State = EGravityBikeSplineAttackShipState::Default;

		SplineMoveComp.SnapSpeed();
		const FTransform NewSplineTransform = SplineMoveComp.GetSplineTransform();
		AttackShip.SetActorVelocity(NewSplineTransform.Rotation.ForwardVector * SplineMoveComp.Speed);

		bShouldExplode = false;

		AccRotation.SnapTo(AttackShip.ActorQuat);
		AttackShip.AccMeshRotation.SnapTo(FQuat::Identity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineAttackShipMoveDeactivateParams Params)
	{
		if(Params.bExplode)
		{
			HealthComp.bExplode = true;
		}
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

		// FVector RelativeLocation = NewSplineTransform.InverseTransformPositionNoScale(AttackShip.ActorLocation);
		// RelativeLocation.X = 0;
		// FVector TargetLocation = NewSplineTransform.TransformPositionNoScale(RelativeLocation);

		FHazeAcceleratedVector AccLocation;
		AccLocation.SnapTo(AttackShip.ActorLocation, AttackShip.ActorVelocity);

		float LocationStiffness;
		float LocationDamping;
		GetLocationSpringValues(LocationStiffness, LocationDamping);

		AccLocation.SpringTo(
			NewSplineTransform.Location,
			LocationStiffness,
			LocationDamping,
			DeltaTime
		);

		FQuat TargetRotation = NewSplineTransform.Rotation;

		if(AttackShip.bFacePlayer.Get())
		{
			const FVector ToGravityBike = GravityBikeSpline::GetGravityBike().ActorLocation - AttackShip.ActorLocation;
			TargetRotation = FQuat::MakeFromZX(NewSplineTransform.Rotation.UpVector, ToGravityBike);
		}

		AccRotation.AccelerateTo(
			TargetRotation,
			GravityBikeSpline::AttackShip::RotationAccelerateDuration,
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
			JoltAlongSpline *= GravityBikeSpline::AttackShip::MeshRotationJoltAlongSplineMultiplier;
			HorizontalJolt *= GravityBikeSpline::AttackShip::MeshRotationHorizontalJoltSplineMultiplier;

			Jolt = JoltAlongSpline + HorizontalJolt;
		}

		const FVector SplineUpVector = SplineMoveComp.EnemySpline.GetUpAtSplineDistance(SplineMoveComp.GetDistanceAlongSpline());
		FVector WorldAngularImpulse = SplineUpVector.CrossProduct(Jolt);

		const FVector RelativeAngularImpulse = AttackShip.ActorTransform.InverseTransformVectorNoScale(WorldAngularImpulse);

		float AngularImpulseMagnitude = RelativeAngularImpulse.Size() * GravityBikeSpline::AttackShip::MeshRotationJoltMultiplier;

		const float Limit = Math::DegreesToRadians(GravityBikeSpline::AttackShip::MeshRotationAngleLimit);
		AngularImpulseMagnitude = Math::Clamp(AngularImpulseMagnitude, -Limit, Limit);

		const FQuat TargetRotation = FQuat(RelativeAngularImpulse.GetSafeNormal(), AngularImpulseMagnitude);

		//Debug::DrawDebugCoordinateSystem(AttackShip.ActorLocation, AttackShip.ActorTransform.TransformRotation(TargetRotation.Rotator()), 500, 10);

		AttackShip.AccMeshRotation.SpringTo(
			TargetRotation,
			GravityBikeSpline::AttackShip::MeshRotationStiffness,
			GravityBikeSpline::AttackShip::MeshRotationDamping,
			DeltaTime
		);

		const FQuat RelativeRotation = GravityBikeSpline::AttackShip::RotationOffset * AttackShip.AccMeshRotation.Value;

		AttackShip.MeshPivot.SetRelativeRotation(RelativeRotation);
	}

	void GetLocationSpringValues(float&out OutStiffness, float&out OutDamping) const
	{
		OutStiffness = GravityBikeSpline::AttackShip::LocationStiffness;
		OutDamping = GravityBikeSpline::AttackShip::LocationDamping;
		
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
		if(AttackShip.DamageImpulseTime < 0)
			return false;

		return Time::GetGameTimeSince(AttackShip.DamageImpulseTime) < 2;
	}

	bool WasRecentlyReflectedOffWall() const
	{
		if(AttackShip.ReflectOffWallTime < 0)
			return false;

		return Time::GetGameTimeSince(AttackShip.ReflectOffWallTime) < 1;
	}
};