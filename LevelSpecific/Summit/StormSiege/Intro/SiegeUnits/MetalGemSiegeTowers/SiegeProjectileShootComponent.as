class USiegeProjectileShootComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<ASiegeBaseProjectile> ProjectileClass;

	UPROPERTY()
	float SpawnRate = 1.2;

	UPROPERTY()
	float PredictionDistance = 6000.0;

	UPROPERTY()
	float RandomizedOffset = 1000.0;

	UPROPERTY()
	float MinRangeRequired = 15000.0;

	UPROPERTY()
	float Speed = 7000.0;

	bool bDebug;

	void SpawnProjectile(AHazePlayerCharacter Target)
	{
		FVector PredictionOffset = Target.ActorForwardVector * PredictionDistance;
		FVector RandomOffset = FVector(Math::RandRange(-RandomizedOffset, RandomizedOffset), Math::RandRange(-RandomizedOffset, RandomizedOffset), Math::RandRange(-RandomizedOffset, RandomizedOffset));
		ASiegeBaseProjectile NewProjectile = SpawnActor(ProjectileClass, WorldLocation, bDeferredSpawn = true);
		NewProjectile.TargetLocation = Target.ActorLocation + PredictionOffset + RandomOffset;
		NewProjectile.SpawnInstigator = Owner;
		NewProjectile.Speed = Speed;
		FinishSpawningActor(NewProjectile);
	}
}