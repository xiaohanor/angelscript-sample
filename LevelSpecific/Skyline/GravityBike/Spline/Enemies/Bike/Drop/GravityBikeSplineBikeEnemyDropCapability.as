enum EGravityBikeSplineBikeEnemyDropFollow
{
	None,
	CargoBay,
	Hatch,
};

struct FGravityBikeSplineBikeEnemyDropDeactivateParams
{
	bool bLanded = false;
};

class UGravityBikeSplineBikeEnemyDropCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50;

	AGravityBikeSplineBikeEnemy BikeEnemy;
	UHazeMovementComponent MoveComp;
	USimpleMovementData MoveData;

	UGravityBikeSplineBikeEnemyDropComponent DropComp;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	AGravityBikeSplineAttackShip AttackShip;
	EGravityBikeSplineBikeEnemyDropFollow Follow = EGravityBikeSplineBikeEnemyDropFollow::None;

	const float CargoBayDuration = 0.2;
	const float HatchDuration = 0.3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(Owner);
		MoveComp = BikeEnemy.MoveComp;
		MoveData = MoveComp.SetupSimpleMovementData();

		DropComp = UGravityBikeSplineBikeEnemyDropComponent::Get(BikeEnemy);
		SplineMoveComp = BikeEnemy.SplineMoveComp;
		HealthComp = BikeEnemy.HealthComp;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!DropComp.bIsDropping)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineBikeEnemyDropDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!DropComp.bIsDropping)
			return true;

		if(MoveComp.HasGroundContact())
		{
			Params.bLanded = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DropComp.bIsDropping = true;
		AttackShip = DropComp.AttackShip;
		BikeEnemy.MovementState = EGravityBikeSplineBikeEnemyMovementState::Drop;
		UMovementGravitySettings::SetGravityAmount(BikeEnemy, 3000.0, this);

		BikeEnemy.AccPitch.SnapTo(0);
		MoveComp.AddMovementIgnoresActor(this, AttackShip);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineBikeEnemyDropDeactivateParams Params)
	{
		DropComp.bIsDropping = false;
		UMovementGravitySettings::ClearGravityAmount(BikeEnemy,  this);

		if(Params.bLanded)
		{
			FVector HorizontalVelocity = BikeEnemy.ActorVelocity.VectorPlaneProject(FVector::UpVector);
			FVector VerticalVelocity = FVector::ZeroVector;
			BikeEnemy.SetActorVelocity(HorizontalVelocity + VerticalVelocity);
			BikeEnemy.AccPitch.Velocity = -200;
		}

		MoveComp.RemoveMovementIgnoresActor(this);

		if(Follow != EGravityBikeSplineBikeEnemyDropFollow::None)
		{
			MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(ActiveDuration < CargoBayDuration)
			MoveInCargoBay();
		else if(ActiveDuration < CargoBayDuration + HatchDuration)
			MoveOnHatch();
		else
			Fall(DeltaTime);

		MoveComp.ApplyMove(MoveData);

		BikeEnemy.ApplyMeshPivotRotation();
	}

	void MoveInCargoBay()
	{
		if(Follow != EGravityBikeSplineBikeEnemyDropFollow::CargoBay)
		{
			MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::Release);
			MoveComp.FollowComponentMovement(AttackShip.MeshComp, this, EMovementFollowComponentType::Teleport);
			Follow = EGravityBikeSplineBikeEnemyDropFollow::CargoBay;
		}

		const float Alpha = ActiveDuration / CargoBayDuration;
		const FVector Start = AttackShip.GetStartOfCargoBay();
		const FVector End = AttackShip.GetStartOfHatch();
		FVector Location = Math::Lerp(Start, End, Alpha);
		Location += BikeEnemy.ActorUpVector * BikeEnemy.SphereComp.SphereRadius;
		MoveData.AddDeltaFromMoveTo(Location);

		FQuat TargetRotation = AttackShip.ActorQuat;
		MoveData.SetRotation(TargetRotation);
	}

	void MoveOnHatch()
	{
		if(Follow != EGravityBikeSplineBikeEnemyDropFollow::Hatch)
		{
			MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::Release);
			MoveComp.FollowComponentMovement(AttackShip.HatchMeshComp, this, EMovementFollowComponentType::Teleport);
			Follow = EGravityBikeSplineBikeEnemyDropFollow::Hatch;
		}

		const float Alpha = Math::GetMappedRangeValueClamped(FVector2D(CargoBayDuration, CargoBayDuration +HatchDuration), FVector2D(0, 1), ActiveDuration);
		const FVector Start = AttackShip.GetStartOfHatch();
		const FVector End = AttackShip.GetEndOfHatch();
		FVector Location = Math::Lerp(Start, End, Alpha);
		Location += BikeEnemy.ActorUpVector * BikeEnemy.SphereComp.SphereRadius;
		MoveData.AddDeltaFromMoveTo(Location);

		FQuat StartRotation = AttackShip.ActorQuat;
		FQuat TargetRotation = FQuat::MakeFromXY(Start - End, AttackShip.ActorRightVector);
		FQuat Rotation = FQuat::Slerp(StartRotation, TargetRotation, Math::GetMappedRangeValueClamped(FVector2D(0, 0.4), FVector2D(0, 1), Alpha));
		MoveData.SetRotation(Rotation);
	}

	void Fall(float DeltaTime)
	{
		if(Follow != EGravityBikeSplineBikeEnemyDropFollow::None)
		{
			MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);
			Follow = EGravityBikeSplineBikeEnemyDropFollow::None;

			// Transfer actor rotation to the accelerated pitch
			FQuat NewActorRotation = FQuat::MakeFromZY(FVector::UpVector, BikeEnemy.ActorRightVector);
			FQuat RelativeRotation = FQuat::GetRelative(NewActorRotation, BikeEnemy.ActorQuat);
			BikeEnemy.AccPitch.SnapTo(RelativeRotation.Rotator().Pitch);
			BikeEnemy.SetActorRotation(NewActorRotation);
		}
		
		MoveData.AddOwnerVelocity();
		MoveData.AddGravityAcceleration();

		FQuat TargetRotation = FQuat::MakeFromXZ(SplineMoveComp.GetSplineTransform().Rotation.ForwardVector, FVector::UpVector);
		FQuat Rotation = Math::QInterpConstantTo(BikeEnemy.ActorQuat, TargetRotation, DeltaTime, 1);
		MoveData.SetRotation(Rotation);

		BikeEnemy.AccPitch.AccelerateTo(30, 0.5, DeltaTime);
	}
};