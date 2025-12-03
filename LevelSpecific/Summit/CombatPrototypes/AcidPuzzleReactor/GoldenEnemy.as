class AGoldenEnemy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UTeenDragonAcidPuddleTrailExplosionResponseComponent ResonseComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	TArray<UStaticMeshComponent> MeshComps;

	bool bExploded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);
		ResonseComp.OnTrailExploded.AddUFunction(this, n"OnTrailExploded");
	}

	UFUNCTION()
	private void OnTrailExploded(ATeenDragonAcidPuddleTrail FromTrail)
	{
		if (bExploded)
			return;

		bExploded = true;

		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 800.0, 5000.0);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 800.0, 5000.0);

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			FVector Impulse = (Mesh.WorldLocation - ActorLocation).GetSafeNormal() * 35000;
			Mesh.SetSimulatePhysics(true);
			Mesh.AddImpulse(Impulse);
		}
	}
}