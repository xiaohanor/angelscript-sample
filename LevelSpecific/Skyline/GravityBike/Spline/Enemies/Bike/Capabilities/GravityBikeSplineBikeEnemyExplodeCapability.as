struct FGravityBikeSplineBikeEnemyExplodeDeactivateParams
{
	bool bRespawn = false;
	float RespawnDistanceAlongSpline;
};

class UGravityBikeSplineBikeEnemyExplodeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;

	AGravityBikeSplineBikeEnemy BikeEnemy;
	//UHazeMovementComponent MoveComp;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BikeEnemy = Cast<AGravityBikeSplineBikeEnemy>(Owner);
		//MoveComp = BikeEnemy.MoveComp;
		SplineMoveComp = BikeEnemy.SplineMoveComp;
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplineMoveComp.HasPassedSplineEnd())
		{
			if(BikeEnemy.MoveComp.HasAnyValidBlockingImpacts())
				return true;
		}

		if(!HealthComp.bExplode)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineBikeEnemyExplodeDeactivateParams& Params) const
	{
		if(!HealthComp.CanRespawn())
			return false;

		bool bRespawn = false;

		if(!HealthComp.bExplode)
			bRespawn = true;

		if(ActiveDuration > 1.0)
			bRespawn = true;

		if(bRespawn)
		{
			Params.bRespawn = true;
			const FVector PlayerSplineLocation = GravityBikeSpline::GetGravityBikeSplineTransform().Location;
			const float PlayerLocationOnOurSpline = SplineMoveComp.GetSplineComp().GetClosestSplineDistanceToWorldLocation(PlayerSplineLocation);
			Params.RespawnDistanceAlongSpline = PlayerLocationOnOurSpline + SplineMoveComp.RespawnOffset;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BikeEnemy.AddActorCollisionBlock(this);
		BikeEnemy.AddActorVisualsBlock(this);

		UGravityBikeSplineBikeEnemyEventHandler::Trigger_OnExplode(BikeEnemy);
		BikeEnemy.ThrowTargetComp.Disable(this);

		HealthComp.bIsRespawning = true;
		BikeEnemy.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);

		BikeEnemy.MovementState = EGravityBikeSplineBikeEnemyMovementState::None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineBikeEnemyExplodeDeactivateParams Params)
	{
		if(!Params.bRespawn)
			return;

		BikeEnemy.RemoveActorCollisionBlock(this);
		BikeEnemy.RemoveActorVisualsBlock(this);

		BikeEnemy.ThrowTargetComp.Enable(this);
		BikeEnemy.MeshPivot.SetRelativeRotation(FQuat::Identity);

		Respawn(Params.RespawnDistanceAlongSpline);
		BikeEnemy.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	void Respawn(float RespawnDistanceAlongSpline)
	{
		SplineMoveComp.SetDistanceAlongSpline(RespawnDistanceAlongSpline);
		FTransform SplineTransform = SplineMoveComp.GetSplineTransform();

		Owner.TeleportActor(SplineTransform.Location, SplineTransform.Rotator(), this);
	
		HealthComp.Respawn();

		BikeEnemy.MeshPivot.SetRelativeRotation(FQuat::Identity);

		BikeEnemy.State = EGravityBikeSplineBikeEnemyState::Default;
	}
};