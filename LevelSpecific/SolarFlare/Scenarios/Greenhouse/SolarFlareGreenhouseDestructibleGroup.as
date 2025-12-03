class ASolarFlareGreenhouseDestructibleGroup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	TArray<UStaticMeshComponent> MeshComps;

	UPROPERTY(EditAnywhere)
	ASolarFlareWaveImpactEventActor EventActor;

	UPROPERTY()
	UNiagaraSystem DestructionSystem;

	UPROPERTY()
	TArray<UMaterialInterface> Materials;

	float BurnLerp = 0.0;
	bool bHasBeenDestroyed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		GetComponentsByClass(MeshComps);
		EventActor.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BurnLerp = Math::FInterpTo(BurnLerp, 1.0, DeltaSeconds, 0.4);

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetScalarParameterValueOnMaterials(n"BurnAmount", BurnLerp);
		}
	}

	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		// if (bHasBeenDestroyed)
		// 	return;

		FSolarFlareGreenhouseDestructibleImpactParams Params;
		Params.Location = ActorLocation;
		USolarFlareGreenhouseDestructibleEffectHandler::Trigger_FlareImpact(this, Params);

		bHasBeenDestroyed = true;

		SetActorTickEnabled(true);
		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DestructionSystem, Mesh.WorldLocation, Mesh.WorldRotation);
		
			for (int i = 0; i < Mesh.Materials.Num(); i++)
			{
				Mesh.SetMaterial(i, Materials[i]);
			}
		}
	}
};