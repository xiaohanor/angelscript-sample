UCLASS(NotBlueprintable)
class UGravityBikeSplineEnemyMissileLauncherComponent : UArrowComponent
{
#if EDITOR
	default ArrowLength = 50;
	default ArrowSize = 10;
#endif

	UPROPERTY(EditDefaultsOnly, Category = "Missile")
	private TSubclassOf<AGravityBikeSplineEnemyMissile> MissileClass;

	TArray<UGravityBikeSplineEnemyFireTriggerComponent> FireInstigators;

	private AGravityBikeSplineEnemy Enemy;
	private int SpawnedMissiles = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Enemy = Cast<AGravityBikeSplineEnemy>(Owner);
		devCheck(Enemy != nullptr, f"EnemyMissileLauncherComponent added to something other than an enemy: {Owner}, this is not valid!");
	}

	void SpawnMissile(FVector Direction, UGravityBikeSplineEnemyFireTriggerComponent FireTriggerComp)
	{
		if(!HasControl())
			return;

		FRotator Rotation;
		if(Direction.IsNearlyZero())
			Rotation = WorldRotation;
		else
			Rotation = FRotator::MakeFromXZ(Direction, WorldRotation.UpVector);

		NetSpawnMissile(WorldLocation, Rotation, FireTriggerComp);
	}

	UFUNCTION(NetFunction)
	private void NetSpawnMissile(FVector Location, FRotator Rotation, UGravityBikeSplineEnemyFireTriggerComponent FireTriggerComp)
	{
		AGravityBikeSplineEnemyMissile Missile = SpawnActor(MissileClass, Location, Rotation, bDeferredSpawn = true);
		Missile.MissileSettings = FireTriggerComp.MissileSettings;
		Missile.LauncherComp = this;

		Missile.MakeNetworked(this, n"Missile", SpawnedMissiles);
		SpawnedMissiles++;
		
		FinishSpawningActor(Missile);
		Missile.AddActorDisable(this);

		if (HasControl())
			CrumbLaunchMissile(Missile);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchMissile(AGravityBikeSplineEnemyMissile Missile)
	{
		Missile.RemoveActorDisable(this);
		Missile.Launch();
	}
};