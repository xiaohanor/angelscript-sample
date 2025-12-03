class UGravityBikeSplineCarEnemyReloadTurretCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBikeSpline::Enemy::EnemyFireTag);
	default CapabilityTags.Add(GravityBikeSpline::CarEnemy::Turret::CarEnemyTurretTag);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	AGravityBikeSplineCarEnemy CarEnemy;
	UGravityBikeSplineCarEnemyTurretComponent TurretComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarEnemy = Cast<AGravityBikeSplineCarEnemy>(Owner);
		TurretComp = UGravityBikeSplineCarEnemyTurretComponent::Get(Owner);
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TurretComp.IsMagazineEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TurretComp.HasFinishedReloading())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TurretComp.StartReload();

		Owner.BlockCapabilities(GravityBikeSpline::CarEnemy::Turret::CarEnemyTurretFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TurretComp.FinishReload();

		Owner.UnblockCapabilities(GravityBikeSpline::CarEnemy::Turret::CarEnemyTurretFireTag, this);
	}
};