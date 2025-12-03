class ASolarFlareGreenhouseDestructible : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DestructionSystem;
	
	UPROPERTY(EditAnywhere)
	UNiagaraSystem MultiDestructionSystem;

	UPROPERTY(EditAnywhere)
	TArray<AStaticMeshActor> Bushes;

	UPROPERTY(EditAnywhere)
	TArray<AActor> RowBurst;

	UPROPERTY(EditAnywhere)
	TArray<UMaterialInterface> Materials;

	UPROPERTY(EditAnywhere)
	ASolarFlareWaveImpactEventActor EventImpactActor;

	float BurnLerp = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EventImpactActor.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");
		SetActorTickEnabled(false);

		for (AActor Actor : RowBurst)
		{
			Actor.SetActorHiddenInGame(true);
			Actor.SetActorEnableCollision(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BurnLerp = Math::FInterpTo(BurnLerp, 1.0, DeltaSeconds, 0.4);

		for (AStaticMeshActor Bush : Bushes)
		{
			if (Bush != nullptr)
				Bush.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"BurnAmount", BurnLerp);
		}
	}

	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		SetActorTickEnabled(true);

		for (AActor Actor : RowBurst)
		{
			if (MultiDestructionSystem != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(MultiDestructionSystem, Actor.ActorLocation);
		}
		
		for (AStaticMeshActor Bush : Bushes)
		{
			for (int i = 0; i < Bush.StaticMeshComponent.Materials.Num(); i++)
			{
				Bush.StaticMeshComponent.SetMaterial(i, Materials[i]);
			}


			Bush.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"BurnAmount", BurnLerp);

			Niagara::SpawnOneShotNiagaraSystemAtLocation(DestructionSystem, Bush.ActorLocation);
			FSolarFlareGreenhouseDestructibleImpactParams Params;
			Params.Location = Bush.ActorLocation;
			USolarFlareGreenhouseDestructibleEffectHandler::Trigger_FlareImpact(this, Params);
		}
	}
}