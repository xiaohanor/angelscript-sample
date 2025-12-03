class ANightQueenLongRangeSieger : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttackOrigin;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"NightQueenLongRangeSiegerAttackCapability");

	UPROPERTY()
	TSubclassOf<ASummitMagicTrajectoryProjectile> ProjectileClass;

	bool bIsActive;

	UFUNCTION()
	void ActivateAggression()
	{
		bIsActive = true;
	}

	UFUNCTION()
	void DeactivateAggression()
	{
		bIsActive = true;
	}

	void SpawnProjectile(AHazeActor Target)
	{
		FRotator RotTarget = (Target.ActorLocation - AttackOrigin.WorldLocation).Rotation();

		// TODO: Use projectile launcher?
		ASummitMagicTrajectoryProjectile Proj = SpawnActor(ProjectileClass, AttackOrigin.WorldLocation, RotTarget, bDeferredSpawn = true);
		Proj.IgnoreActors.Add(this);
		Proj.TargetLocation = Target.ActorLocation;
		Proj.Speed = 8200.0;
		Proj.Gravity = 1200.0;
		FinishSpawningActor(Proj);
	}
} 