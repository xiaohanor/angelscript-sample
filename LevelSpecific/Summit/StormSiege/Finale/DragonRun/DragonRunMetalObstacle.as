class ADragonRunMetalObstacle : ANightQueenMetal
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY()
	UNiagaraSystem Explosion;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	TArray<UStaticMeshComponent> MeshComps;

	float ImpulseForce = 65000.0;
	bool bIsDestroyed;

	float ShrinkTime;
	float ShrinkDuration = 12.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GetComponentsByClass(MeshComps);
		// for (UStaticMeshComponent Mesh : MeshComps)
		// {
		// 	if (Mesh != MeshComp)
		// 		Mesh.SetHiddenInGame(true);
		// }

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnStormRideAcidHit");
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > ShrinkTime)
		{
			DestroyActor();
		}
	}

	UFUNCTION()
	private void OnStormRideAcidHit(FAcidHit Hit)
	{
		if (bIsDestroyed)
			return;

		bIsDestroyed = true;
		BlockingVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			if (Mesh == MeshComp)
				continue;

			// Mesh.SetHiddenInGame(false);
			Mesh.SetSimulatePhysics(true);
			FVector Impulse = (Mesh.WorldLocation - ActorLocation).GetSafeNormal() * ImpulseForce;
			Mesh.AddImpulse(Impulse);
		}

		MeshComp.SetHiddenInGame(true);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(Explosion, ActorLocation);
		ShrinkTime = Time::GameTimeSeconds + ShrinkDuration;

		Game::Mio.PlayWorldCameraShake(ImpactCameraShake, this, ActorLocation, 1500.0, 8000.0);
		Game::Zoe.PlayWorldCameraShake(ImpactCameraShake, this, ActorLocation, 1500.0, 8000.0);

		SetActorTickEnabled(true);
	}
}