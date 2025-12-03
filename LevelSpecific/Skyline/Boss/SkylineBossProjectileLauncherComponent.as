class USkylineBossProjectileLauncherComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossProjectile> ProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	float LaunchSpeed = 10000.0;

	ASkylineBossProjectile PreparedProjectile;

	ASkylineBossProjectile PrepareProjectileLaunch(AHazeActor Target)
	{
		PreparedProjectile = SpawnActor(ProjectileClass, bDeferredSpawn = true);

		PreparedProjectile.Target = Target;

		return PreparedProjectile;
	}

	void LaunchPreparedProjectile(TArray<AActor> ActorsToIgnore)
	{
		PreparedProjectile.ActorsToIgnore.Add(Owner);
		PreparedProjectile.ActorsToIgnore.Append(ActorsToIgnore);

		PreparedProjectile.Velocity = ForwardVector * LaunchSpeed;

		FTransform SpawnTransform = WorldTransform;
		SpawnTransform.Scale3D = FVector::OneVector;

		FinishSpawningActor(PreparedProjectile, SpawnTransform);
	}
}