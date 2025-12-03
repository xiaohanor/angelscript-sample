UCLASS(Abstract)
class USandHandForceFeedbackEventHandler : USandHandEventHandler
{
	UPROPERTY()
	UForceFeedbackEffect SandHandSpawnedForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect SandHandShotForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect SandHandHitForceFeedback;

	UFUNCTION(BlueprintOverride)
	void OnSandHandSpawned(FSandHandSpawnedData SpawnedData)
	{
		if(SandHandSpawnedForceFeedback != nullptr)
			PlayerOwner.PlayForceFeedback(SandHandSpawnedForceFeedback, false, true, n"SandHandSpawned");
	}

	UFUNCTION(BlueprintOverride)
	void OnSandHandShot(FSandHandShotData ShotData)
	{
		if(SandHandSpawnedForceFeedback != nullptr)
			PlayerOwner.PlayForceFeedback(SandHandShotForceFeedback, false, true, n"SandHandShot");
	}

	UFUNCTION(BlueprintOverride)
	void OnSandHandProjectileHit(FSandHandHitData HitData)
	{
		// if(SandHandHitForceFeedback != nullptr)
		// 	PlayerOwner.PlayForceFeedback(SandHandHitForceFeedback, false, true, n"SandHandHit");

		ASandHandProjectile SandHand = Cast<ASandHandProjectile>(HitData.SandHandProjectile);
		if (SandHand != nullptr)
			SandHand.ImpactForceFeedbackComp.Play();
	}
}