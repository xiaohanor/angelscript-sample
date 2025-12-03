struct FGravityBikeSplineCarEnemyVeerActivateParams
{
	bool bVeerLeft;
}

struct FGravityBikeSplineCarEnemyVeerDeactivateParams
{
	bool bExplode = false;
}

class UGravityBikeSplineCarEnemyVeerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	AGravityBikeSplineCarEnemy CarEnemy;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UHazeMovementComponent MoveComp;
	UGravityBikeSplineFlyingEnemyMovementData MoveData;

	bool bVeerLeft = false;
	bool bShouldExplode = false;

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
	bool ShouldActivate(FGravityBikeSplineCarEnemyVeerActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(HealthComp.IsAlive())
			return false;

		if(HealthComp.IsRespawning())
			return false;

		const FTransform GravityBikeSplineTransform = GravityBikeSpline::GetGravityBikeSplineTransform();
		const FVector EnemyRelativeToSpline = GravityBikeSplineTransform.InverseTransformPositionNoScale(CarEnemy.ActorLocation);

		// Veer to the center of the spline
		Params.bVeerLeft = EnemyRelativeToSpline.Y > 0;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineCarEnemyVeerDeactivateParams& Params) const
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

		if(ActiveDuration > GravityBikeSpline::CarEnemy::ExplodeAfterVeerDelay)
		{
			Params.bExplode = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineCarEnemyVeerActivateParams Params)
	{
		CarEnemy.State = EGravityBikeSplineCarEnemyState::Veering;

		bVeerLeft = Params.bVeerLeft;
		bShouldExplode = false;

		UGravityBikeSplineCarEnemyEventHandler::Trigger_OnStartVeering(CarEnemy);
		CarEnemy.ThrowTargetComp.Disable(this);

		CarEnemy.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineCarEnemyVeerDeactivateParams Params)
	{
		CarEnemy.ThrowTargetComp.Enable(this);

		if(Params.bExplode)
		{
			HealthComp.bExplode = true;
		}

		CarEnemy.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
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
		FVector Velocity = CarEnemy.ActorVelocity;

		if(Velocity.Size() > GravityBikeSpline::CarEnemy::VeerMaxSpeed)
		{
			Velocity = Acceleration::VInterpVelocityConstantToFramerateIndependent(
				Velocity, Velocity.GetSafeNormal() * GravityBikeSpline::CarEnemy::VeerMaxSpeed,
				DeltaTime,
				GravityBikeSpline::CarEnemy::VeerDeceleration,
				Delta
			);
		}

		Acceleration::ApplyAccelerationToVelocity(
			Velocity,
			FVector::DownVector * GravityBikeSpline::CarEnemy::VeerGravity,
			DeltaTime,
			Delta
		);

		const float TurnSpeed = GetTurnSpeed();
		const FQuat VeerRotationalDelta = FQuat(CarEnemy.ActorUpVector, TurnSpeed * DeltaTime);
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
		CarEnemy.MeshPivot.AddRelativeRotation(FRotator(0, 0, RollSpeed * DeltaTime));
	}

	float GetTurnSpeed() const
	{
		float TurnSpeed = GravityBikeSpline::CarEnemy::VeerTurnSpeed;
		if(bVeerLeft)
			TurnSpeed *= -1;

		return TurnSpeed;
	}

	float GetRollSpeed() const
	{
		float RollSpeed = GravityBikeSpline::CarEnemy::VeerRollSpeed;
		if(bVeerLeft)
			RollSpeed *= -1;

		return RollSpeed;
	}
};