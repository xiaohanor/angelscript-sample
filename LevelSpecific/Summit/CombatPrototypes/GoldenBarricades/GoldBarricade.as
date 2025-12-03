class AGoldBarricade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ProtectedGem;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp; 

	UPROPERTY(DefaultComponent)
	UTeenDragonTailBombImpactResponseComponent BombResponseComp;

	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem GemAttacker;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UNiagaraSystem AcidExplosion;

	TArray<UStaticMeshComponent> MeshComps;

	float ImpulseAmount = 1525000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);
		BombResponseComp.OnExplodedEvent.AddUFunction(this, n"OnExplodedEvent");
	}
	
	UFUNCTION()
	private void OnExplodedEvent(FTeenDragonTailBombImpactResonseData Data)
	{
		OnDestroyBarricade(Data.Bomb.ActorLocation);
	}

	UFUNCTION()
	private void OnDestroyBarricade(FVector ImpactLocation)
	{
		for (UStaticMeshComponent Mesh : MeshComps)
		{
			if (Mesh == ProtectedGem)
				continue;

			Mesh.SetSimulatePhysics(true);
			FVector ImpactDirection = (Mesh.WorldLocation - ImpactLocation).GetSafeNormal();
			FVector Impulse = ImpactDirection * ImpulseAmount;
			Mesh.AddImpulse(Impulse);
			Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		}

		ProtectedGem.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ProtectedGem.SetHiddenInGame(true);
		if (GemAttacker != nullptr)
			GemAttacker.DestroyActor();

		Game::Mio.PlayCameraShake(CameraShake, this, 1.5);
		Game::Zoe.PlayCameraShake(CameraShake, this, 1.5);
		BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(AcidExplosion, ActorLocation);
	}
}