class UGravityBikeSplineEnemyCutsceneCapability : UHazeCapability
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
		if(!Enemy.bDisableDuringCutscenes)
			return false;
		
		if(!GravityBikeSpline::GetGravityBike().bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Enemy.bDisableDuringCutscenes)
			return true;

		if(!GravityBikeSpline::GetGravityBike().bIsControlledByCutscene)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Enemy.AddActorCollisionBlock(this);
		Enemy.AddActorVisualsBlock(this);

		Enemy.BlockCapabilities(CapabilityTags::BlockedByCutscene, this);
		Enemy.BlockCapabilities(CapabilityTags::Movement, this);
		Enemy.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Enemy.BlockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Enemy.RemoveActorCollisionBlock(this);
		Enemy.RemoveActorVisualsBlock(this);

		Enemy.UnblockCapabilities(CapabilityTags::BlockedByCutscene, this);
		Enemy.UnblockCapabilities(CapabilityTags::Movement, this);
		Enemy.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Enemy.UnblockCapabilities(GravityBikeSpline::Enemy::EnemyFireTag, this);
	}
};