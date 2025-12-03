struct FGravityBikeSplineAttackShipVeerActivateParams
{
	bool bVeerLeft;
}

struct FGravityBikeSplineAttackShipVeerDeactivateParams
{
	bool bExplode = false;
}

class UGravityBikeSplineAttackShipVeerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	AGravityBikeSplineAttackShip AttackShip;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UHazeMovementComponent MoveComp;
	UGravityBikeSplineFlyingEnemyMovementData MoveData;

	bool bVeerLeft = false;
	bool bShouldExplode = false;

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
	bool ShouldActivate(FGravityBikeSplineAttackShipVeerActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(HealthComp.IsAlive())
			return false;

		if(HealthComp.IsRespawning())
			return false;

		const FTransform GravityBikeSplineTransform = GravityBikeSpline::GetGravityBikeSplineTransform();
		const FVector EnemyRelativeToSpline = GravityBikeSplineTransform.InverseTransformPositionNoScale(AttackShip.ActorLocation);

		// Veer to the center of the spline
		Params.bVeerLeft = EnemyRelativeToSpline.Y > 0;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineAttackShipVeerDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(HealthComp.IsAlive())
			return true;

		if(HealthComp.IsRespawning())
			return true;

		if(bShouldExplode)
		{
			Params.bExplode = true;
			return true;
		}

		if(ActiveDuration > GravityBikeSpline::AttackShip::ExplodeAfterVeerDelay)
		{
			Params.bExplode = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineAttackShipVeerActivateParams Params)
	{
		AttackShip.State = EGravityBikeSplineAttackShipState::Veering;

		bVeerLeft = Params.bVeerLeft;
		bShouldExplode = false;

		UGravityBikeSplineAttackShipEventHandler::Trigger_OnStartVeering(AttackShip);
		AttackShip.ThrowTargetComp.Disable(this);

		AttackShip.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineAttackShipVeerDeactivateParams Params)
	{
		AttackShip.ThrowTargetComp.Enable(this);

		if(Params.bExplode)
		{
			HealthComp.bExplode = true;
		}

		AttackShip.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
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
		FVector Delta = FVector::ZeroVector;
		FVector Velocity = AttackShip.ActorVelocity;

		if(Velocity.Size() > GravityBikeSpline::AttackShip::VeerMaxSpeed)
		{
			Velocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(
				Velocity, Velocity.GetSafeNormal() * GravityBikeSpline::AttackShip::VeerMaxSpeed,
				DeltaTime,
				GravityBikeSpline::AttackShip::VeerDeceleration,
				Delta
			);
		}

		Acceleration::ApplyAccelerationToVelocity(
			Velocity,
			FVector::DownVector * GravityBikeSpline::AttackShip::VeerGravity,
			DeltaTime,
			Delta
		);

		const float TurnSpeed = GetTurnSpeed();
		const FQuat VeerRotationalDelta = FQuat(AttackShip.ActorUpVector, TurnSpeed * DeltaTime);
		Velocity = VeerRotationalDelta * Velocity;

		Delta += Velocity * DeltaTime;

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		const FQuat Rotation = Velocity.ToOrientationQuat();
		MoveData.SetRotation(Rotation);

		MoveData.ApplyIgnoreResponseComponents();
		MoveData.ApplyShouldExplodeOnImpact();
	}

	void TickMeshRotation(float DeltaTime)
	{
		const float RollSpeed = GetRollSpeed();
		AttackShip.MeshPivot.AddRelativeRotation(FRotator(0, 0, RollSpeed * DeltaTime));
	}

	float GetTurnSpeed() const
	{
		float TurnSpeed = GravityBikeSpline::AttackShip::VeerTurnSpeed;
		if(bVeerLeft)
			TurnSpeed *= -1;

		return TurnSpeed;
	}

	float GetRollSpeed() const
	{
		float RollSpeed = GravityBikeSpline::AttackShip::VeerRollSpeed;
		if(bVeerLeft)
			RollSpeed *= -1;

		return RollSpeed;
	}
};