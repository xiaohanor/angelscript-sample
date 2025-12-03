UCLASS(Abstract)
class USandHandCameraEventHandler : USandHandEventHandler
{
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SandHandSpawnedCameraShakeClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SandHandShotCameraShakeClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SandHandHitCameraShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SandHandHitWorldCameraShake;

	UFUNCTION(BlueprintOverride)
	void OnSandHandSpawned(FSandHandSpawnedData SpawnedData)
	{
		PlayerOwner.PlayCameraShake(SandHandSpawnedCameraShakeClass, n"SandHandSpawned");
	}

	UFUNCTION(BlueprintOverride)
	void OnSandHandShot(FSandHandShotData ShotData)
	{
		FHazeCameraImpulse CameraImpulse;
		CameraImpulse.CameraSpaceImpulse = FVector(1000, 0.0, 0.0);
		CameraImpulse.ExpirationForce = 1000.0;
		CameraImpulse.Dampening = 0.2;
		PlayerOwner.ApplyCameraImpulse(CameraImpulse, this);

		PlayerOwner.PlayCameraShake(SandHandShotCameraShakeClass, n"SandHandShot");
	}

	UFUNCTION(BlueprintOverride)
	void OnSandHandProjectileHit(FSandHandHitData HitData)
	{
		//PlayerOwner.PlayCameraShake(SandHandHitCameraShake, n"SandHandHit");

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(SandHandHitWorldCameraShake, this, HitData.SandHandProjectile.ActorLocation, 600.0, 1400.0);
	}
}