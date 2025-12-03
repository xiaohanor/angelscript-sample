class USkylineFlyingCarEnemyDropBombCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingCarEnemyDropBomb");

	ASkylineFlyingCarEnemy FlyingCarEnemy;

	float Range = 12000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingCarEnemy = Cast<ASkylineFlyingCarEnemy>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < FlyingCarEnemy.ProjectileLauncherComponent.LaunchInterval)
			return false;
		if (!HasValidTarget())
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
		SpawnActor(FlyingCarEnemy.ProjectileLauncherComponent.ProjectileClass, FlyingCarEnemy.ProjectileLauncherComponent.WorldLocation, FlyingCarEnemy.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool HasValidTarget() const
	{
		if (FlyingCarEnemy.FollowTarget == nullptr)
			return false;

		if (FlyingCarEnemy.FollowTarget.GetDistanceTo(Owner) > Range)
			return false;

		return true;
	}

};