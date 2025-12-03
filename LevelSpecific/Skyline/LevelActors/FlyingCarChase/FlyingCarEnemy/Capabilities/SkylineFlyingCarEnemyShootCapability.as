class USkylineFlyingCarEnemyShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingCarEnemyShoot");

	ASkylineFlyingCarEnemy FlyingCarEnemy;

	float Range = 12000.0;

	float MagSize = 3.0;

	bool bCanShoot = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingCarEnemy = Cast<ASkylineFlyingCarEnemy>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MagSize==0)
			return false;		
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
	
			FVector Direction = (FlyingCarEnemy.FollowTarget.ActorLocation - FlyingCarEnemy.ProjectileLauncherComponent.WorldLocation).GetSafeNormal(); 
			FlyingCarEnemy.ProjectileLauncherComponent.Launch(Owner.ActorVelocity + (Direction * FlyingCarEnemy.ProjectileLauncherComponent.LaunchSpeed));

			UFlyingCarEnemyEventHandler::Trigger_OnShoot(FlyingCarEnemy);
			UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(FlyingCarEnemy.ProjectileLauncherComponent, 1, 1));
			MagSize--;

			if(MagSize==0)
				Timer::SetTimer(this, n"Reload", 2.0);
	
	}

	UFUNCTION()
	private void Reload()
	{
		MagSize=3.0;
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
}