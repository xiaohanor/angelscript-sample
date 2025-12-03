class UGravityBikeSplineEnemyMissileLauncherCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(GravityBikeSpline::Enemy::EnemyFireTag);
	default CapabilityTags.Add(GravityBikeSpline::EnemyMissile::EnemyMissileTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineEnemy Enemy;
	UGravityBikeSplineEnemyMissileLauncherComponent LauncherComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<AGravityBikeSplineEnemy>(Owner);
		LauncherComp = UGravityBikeSplineEnemyMissileLauncherComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Only control can spawn missiles
		if(!HasControl())
			return false;

		if(LauncherComp.FireInstigators.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeSplineEnemyFireTriggerComponent FireComp = LauncherComp.FireInstigators.Last();
		LauncherComp.SpawnMissile(
			FireComp.GetFireDirection(),
			FireComp
		);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Pop the fire instigator we just used to fire
		if(!LauncherComp.FireInstigators.IsEmpty())
			LauncherComp.FireInstigators.RemoveAt(LauncherComp.FireInstigators.Num() - 1);
	}
};