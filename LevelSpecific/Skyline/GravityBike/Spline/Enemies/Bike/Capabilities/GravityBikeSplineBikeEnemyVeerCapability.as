struct FGravityBikeSplineBikeEnemyVeerDeactivateParams
{
	bool bShouldExplode = false;
	bool bShouldStartCrashing = false;
}

class UGravityBikeSplineBikeEnemyVeerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	AGravityBikeSplineBikeEnemy BikeEnemy;
	UHazeMovementComponent MoveComp;
	USimpleMovementData MoveData;

	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	bool bVeerLeft = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(Owner);
		MoveComp = BikeEnemy.MoveComp;
		MoveData = MoveComp.SetupSimpleMovementData();

		SplineMoveComp = BikeEnemy.SplineMoveComp;
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(BikeEnemy.State != EGravityBikeSplineBikeEnemyState::Default)
			return false;

		if(HealthComp.bExplode)
			return false;

		if(!BikeEnemy.HasDriver())
			return true;

		if(HealthComp.IsAlive())
			return false;

		if(HealthComp.IsRespawning())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineBikeEnemyVeerDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(BikeEnemy.State != EGravityBikeSplineBikeEnemyState::Veering)
			return true;

		if(MoveComp.HasImpactedWall() || MoveComp.HasImpactedCeiling())
		{
			Params.bShouldExplode = true;
			return true;
		}

		if(HealthComp.bExplode)
			return true;

		if(ActiveDuration > BikeEnemy.AfterNoDriverDelay)
		{
			Params.bShouldStartCrashing = true;
			return true;
		}

		if(BikeEnemy.MoveComp.IsInAir())
		{
			Params.bShouldStartCrashing = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BikeEnemy.State = EGravityBikeSplineBikeEnemyState::Veering;
		BikeEnemy.ThrowTargetComp.Disable(this);

		BikeEnemy.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
		
		BikeEnemy.MovementState = EGravityBikeSplineBikeEnemyMovementState::None;
	
		bVeerLeft = BikeEnemy.AccRoll.Value > 0;
		SplineMoveComp.ForceSpeed.Apply(1, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineBikeEnemyVeerDeactivateParams Params)
	{
		BikeEnemy.ThrowTargetComp.Enable(this);

		if(Params.bShouldExplode)
		{
			HealthComp.bExplode = true;
		}
		else if(Params.bShouldStartCrashing)
		{
			auto DamageData = FGravityBikeSplineEnemyTakeDamageData(
				EGravityBikeSplineEnemyDamageType::Throwable,
				1,
				true,
				FVector::ZeroVector
			);

			BikeEnemy.HealthComp.TakeDamage(DamageData);
			BikeEnemy.State = EGravityBikeSplineBikeEnemyState::Crashing;
		}

		BikeEnemy.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
		SplineMoveComp.ForceSpeed.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TickSplineMovement(DeltaTime);
		TickMovement(DeltaTime);

		if(HasControl() && ActiveDuration > 0.2 && (BikeEnemy.HasDriver() || BikeEnemy.HasPassenger()))
			CrumbEjectDriverAndPassenger();

		BikeEnemy.RollFromAngularSpeed(DeltaTime);
		BikeEnemy.AccPitch.AccelerateTo(0, 0.1, DeltaTime);
		BikeEnemy.ApplyMeshPivotRotation();
	}

	void TickSplineMovement(float DeltaTime)
	{
		const float TargetSpeed = SplineMoveComp.MaximumSpeed;
		const float InterpSpeed = (TargetSpeed > SplineMoveComp.Speed) ? SplineMoveComp.Acceleration : SplineMoveComp.Deceleration;
		SplineMoveComp.Speed = Math::FInterpConstantTo(SplineMoveComp.Speed, TargetSpeed, DeltaTime, InterpSpeed);
	}

	void TickMovement(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		MoveData.AddGravityAcceleration();

		float Steering = Math::Saturate(ActiveDuration / 0.2);
		Steering = Math::Pow(Steering, 2);
		if(bVeerLeft)
			Steering = -Steering;

		FQuat SteerRotationDelta = FQuat(MoveComp.GroundContact.Normal, Steering * 0.2 * DeltaTime);
		
		FVector Velocity = MoveComp.Velocity;
		FVector HorizontalVelocity = Velocity.VectorPlaneProject(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;
		MoveData.AddVelocity(VerticalVelocity);

		HorizontalVelocity = SteerRotationDelta * HorizontalVelocity;

		HorizontalVelocity = (HorizontalVelocity.GetSafeNormal() * SplineMoveComp.Speed);

		MoveData.AddVelocity(HorizontalVelocity);

		if(!MoveComp.Velocity.VectorPlaneProject(MoveComp.CurrentGroundNormal).IsNearlyZero())
		{
			const FQuat TargetRotation = FQuat::MakeFromZX(MoveComp.CurrentGroundNormal, MoveComp.Velocity);
			MoveData.InterpRotationTo(TargetRotation, 10);
		}

		MoveComp.ApplyMove(MoveData);
	}

	UFUNCTION(CrumbFunction)
	void CrumbEjectDriverAndPassenger()
	{
		BikeEnemy.EjectDriver();
		BikeEnemy.EjectPassenger();
	}
};