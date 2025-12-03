class UGravityBikeSplineEnemyBlockFireCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -100;

	AGravityBikeSplineEnemy Enemy;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<AGravityBikeSplineEnemy>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ShouldBlock())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ShouldBlock())
			return false;

		if(Enemy.GetEnabledDuration() < GravityBikeSpline::Enemy::FireTriggerDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Enemy.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Enemy.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	bool ShouldBlock() const
	{
		if(!Enemy.DeactivateInstigators.IsEmpty())
			return true;

		if(Game::Mio.IsPlayerDead())
			return true;

		return false;
	}
};