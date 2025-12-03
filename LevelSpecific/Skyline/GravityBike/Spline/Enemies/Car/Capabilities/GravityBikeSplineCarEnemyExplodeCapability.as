struct FGravityBikeSplineCarEnemyExplodeDeactivateParams
{
	bool bRespawn = false;
	float RespawnDistanceAlongSpline;
};

class UGravityBikeSplineCarEnemyExplodeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;

	AGravityBikeSplineCarEnemy CarEnemy;
	UHazeMovementComponent MoveComp;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<AGravityBikeSplineCarEnemy>(Owner);
		MoveComp = CarEnemy.MoveComp;
		SplineMoveComp = CarEnemy.SplineMoveComp;
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
	bool ShouldDeactivate(FGravityBikeSplineCarEnemyExplodeDeactivateParams& Params) const
	{
		if(!HealthComp.CanRespawn())
			return false;

		bool bRespawn = false;
		if(!HealthComp.bExplode)
			bRespawn = true;

		if(ActiveDuration > GravityBikeSpline::CarEnemy::RespawnDelay)
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
		CarEnemy.State = EGravityBikeSplineCarEnemyState::Dead;

		if(!HealthComp.IsDead())
			HealthComp.TakeDamage(FGravityBikeSplineEnemyTakeDamageData(EGravityBikeSplineEnemyDamageType::Missile, 1, true, FVector::ZeroVector));
		
		CarEnemy.AddActorCollisionBlock(this);
		CarEnemy.AddActorVisualsBlock(this);

		UGravityBikeSplineCarEnemyEventHandler::Trigger_OnExplode(CarEnemy);
		CarEnemy.ThrowTargetComp.Disable(this);

		HealthComp.bIsRespawning = true;
		CarEnemy.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineCarEnemyExplodeDeactivateParams Params)
	{
		if(!Params.bRespawn)
			return;

		CarEnemy.RemoveActorCollisionBlock(this);
		CarEnemy.RemoveActorVisualsBlock(this);

		CarEnemy.ThrowTargetComp.Enable(this);
		CarEnemy.MeshPivot.SetRelativeRotation(GravityBikeSpline::CarEnemy::RotationOffset);

		SplineMoveComp.SetDistanceAlongSpline(Params.RespawnDistanceAlongSpline);
		FTransform RespawnTransform = SplineMoveComp.GetSplineTransform();
		
		CarEnemy.TeleportActor(RespawnTransform.Location, RespawnTransform.Rotator(), this);
		HealthComp.Respawn();

		CarEnemy.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}
};