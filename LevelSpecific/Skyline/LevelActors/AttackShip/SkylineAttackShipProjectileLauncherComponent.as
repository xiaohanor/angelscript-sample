class USkylineAttackShipProjectileLauncherComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineAttackShipProjectileBase> ProjectileClass;

	UPROPERTY(EditDefaultsOnly)
	float MaxRandomLaunchAngle = 45.0;

	UPROPERTY(EditAnywhere)
	bool bLeftLauncher = false;

	ASkylineAttackShipProjectileBase PreparedProjectile;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Initialize()
	{
		if (SpawnPool == nullptr)
			SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(ProjectileClass, Owner);
	}

	ASkylineAttackShipProjectileBase SpawnProjectile()
	{
		if (!HasControl())
			return nullptr;

		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Spawner = this;

		auto Projectile = Cast<ASkylineAttackShipProjectileBase>(SpawnPool.SpawnControl(SpawnParams));
		Projectile.OnExpired.AddUFunction(this, n"OnProjectileExpired");
		return Projectile;
	}

	UFUNCTION()
	private void OnProjectileExpired(ASkylineAttackShipProjectileBase Projectile)
	{
		SpawnPool.UnSpawn(Projectile);
		Projectile.OnExpired.Unbind(this, n"OnProjectileExpired");
	}

	void LaunchProjectile(ASkylineAttackShipProjectileBase Projectile, AActor Target)
	{
		Projectile.Target = Target;
		Projectile.ActorsToIgnore.Reset();
		Projectile.ActorsToIgnore.Add(Owner);
		
		auto Team = HazeTeam::GetTeam(n"SkylineAttackShips");
		for (auto Member : Team.GetMembers())
		{
			if (Member == nullptr)
				continue;
			Projectile.ActorsToIgnore.Add(Member);
		}

		FTransform SpawnTransform = WorldTransform;
		SpawnTransform.Rotation = Math::GetRandomConeDirection(ForwardVector, Math::DegreesToRadians(MaxRandomLaunchAngle), 0.0).ToOrientationQuat();
		SpawnTransform.Scale3D = FVector::OneVector;

	//	Debug::DrawDebugLine(WorldLocation, WorldLocation + SpawnTransform.Rotation.ForwardVector * 500.0, FLinearColor::Green, 10.0, 1.0);
	//	FinishSpawningActor(PreparedProjectile, SpawnTransform);
		Projectile.Launch(SpawnTransform);
	}
}