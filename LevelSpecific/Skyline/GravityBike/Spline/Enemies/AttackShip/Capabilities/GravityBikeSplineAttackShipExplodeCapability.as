struct FGravityBikeSplineAttackShipExplodeDeactivateParams
{
	bool bRespawn = false;
	float RespawnDistanceAlongSpline;
};

class UGravityBikeSplineAttackShipExplodeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;

	AGravityBikeSplineAttackShip AttackShip;
	UHazeMovementComponent MoveComp;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<AGravityBikeSplineAttackShip>(Owner);
		MoveComp = AttackShip.MoveComp;
		SplineMoveComp = AttackShip.SplineMoveComp;
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HealthComp.bExplode)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineAttackShipExplodeDeactivateParams& Params) const
	{
		if(!HealthComp.CanRespawn())
			return false;

		bool bRespawn = false;
		if(!HealthComp.bExplode)
			bRespawn = true;

		if(ActiveDuration > GravityBikeSpline::AttackShip::RespawnDelay)
			bRespawn = true;

		if(bRespawn)
		{
			const FVector PlayerSplineLocation = GravityBikeSpline::GetGravityBikeSplineTransform().Location;
			const float PlayerLocationOnOurSpline = SplineMoveComp.GetSplineComp().GetClosestSplineDistanceToWorldLocation(PlayerSplineLocation);
			Params.bRespawn = true;
			Params.RespawnDistanceAlongSpline = PlayerLocationOnOurSpline + SplineMoveComp.RespawnOffset;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttackShip.State = EGravityBikeSplineAttackShipState::Dead;

		if(!HealthComp.IsDead())
		{
			FGravityBikeSplineEnemyTakeDamageData TakeDamageData = FGravityBikeSplineEnemyTakeDamageData(
				EGravityBikeSplineEnemyDamageType::Missile,
				1,
				true,
				FVector::ZeroVector
			);

			HealthComp.TakeDamage(TakeDamageData);
		}

		BlockCollisionAndVisuals();

		UGravityBikeSplineAttackShipEventHandler::Trigger_OnExplode(AttackShip);
		AttackShip.ThrowTargetComp.Disable(this);

		HealthComp.bIsRespawning = true;
		AttackShip.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineAttackShipExplodeDeactivateParams Params)
	{
		if(!Params.bRespawn)
			return;

		UnblockCollisionAndVisuals();

		AttackShip.ThrowTargetComp.Enable(this);
		AttackShip.MeshPivot.SetRelativeRotation(GravityBikeSpline::AttackShip::RotationOffset);

		SplineMoveComp.SetDistanceAlongSpline(Params.RespawnDistanceAlongSpline);
		FTransform RespawnTransform = SplineMoveComp.GetSplineTransform();

		AttackShip.TeleportActor(RespawnTransform.Location, RespawnTransform.Rotator(), this);
		HealthComp.Respawn();

		AttackShip.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	void BlockCollisionAndVisuals()
	{
		AttackShip.AddActorCollisionBlock(this);
		AttackShip.AddActorVisualsBlock(this);

		AttackShip.LeftThrusterSpawnerComp.Thruster.AddActorCollisionBlock(this);
		AttackShip.LeftThrusterSpawnerComp.Thruster.AddActorVisualsBlock(this);

		AttackShip.RightThrusterSpawnerComp.Thruster.AddActorCollisionBlock(this);
		AttackShip.RightThrusterSpawnerComp.Thruster.AddActorVisualsBlock(this);
	}

	void UnblockCollisionAndVisuals()
	{
		AttackShip.RemoveActorCollisionBlock(this);
		AttackShip.RemoveActorVisualsBlock(this);

		AttackShip.LeftThrusterSpawnerComp.Thruster.RemoveActorCollisionBlock(this);
		AttackShip.LeftThrusterSpawnerComp.Thruster.RemoveActorVisualsBlock(this);

		AttackShip.RightThrusterSpawnerComp.Thruster.RemoveActorCollisionBlock(this);
		AttackShip.RightThrusterSpawnerComp.Thruster.RemoveActorVisualsBlock(this);
	}
};