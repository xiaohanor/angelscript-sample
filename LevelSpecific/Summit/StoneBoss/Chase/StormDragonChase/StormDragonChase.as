class AStormDragonChase : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonFollowSplineCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonChaseMultiLightningAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormDragonReleaseMagicSphereCapability");

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 10500.0;

	UPROPERTY()
	TSubclassOf<ASummitStormMagicSphere> MagicSphereClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LightningCameraShake;

	TArray<AActor> LightningPoints;

	bool bActivateLightningAttack;
	bool bActivateMagicSpheres;

	UFUNCTION()
	void ActivateLightningAttack(TArray<AActor> HitPoints)
	{
		LightningPoints = HitPoints;
		bActivateLightningAttack = true;
	}

	UFUNCTION()
	void ActivateMagicSpheres()
	{
		bActivateMagicSpheres = true;
	}

	UFUNCTION()
	void DeactivateMagicSpheres()
	{
		bActivateMagicSpheres = false;
	}

	void SpawnMagicSphere(FVector Location)
	{
		ASummitStormMagicSphere MagicSphere = SpawnActor(MagicSphereClass, Location, bDeferredSpawn = true);
		FVector AverageLoc = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		MagicSphere.FloatDirection = (AverageLoc - Location).GetSafeNormal(); 
		FinishSpawningActor(MagicSphere); 
	}
}