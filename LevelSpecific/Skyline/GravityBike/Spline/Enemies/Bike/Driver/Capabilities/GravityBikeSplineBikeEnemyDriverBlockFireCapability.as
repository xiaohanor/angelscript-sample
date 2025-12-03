class UGravityBikeSplineBikeEnemyDriverBlockFireCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -90;

	AGravityBikeSplineBikeEnemyDriver Driver;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Driver = Cast<AGravityBikeSplineBikeEnemyDriver>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Driver.Bike == nullptr)
			return false;

		if(!Driver.Bike.IsCapabilityTagBlocked(GravityBikeSpline::Enemy::EnemyFireTag))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Driver.Bike == nullptr)
			return true;

		if(!Driver.Bike.IsCapabilityTagBlocked(GravityBikeSpline::Enemy::EnemyFireTag))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Driver.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Driver.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}
};