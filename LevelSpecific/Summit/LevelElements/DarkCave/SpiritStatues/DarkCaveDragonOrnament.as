event void FOnDarkCaveDragonSpiritFreed();

class ADarkCaveDragonOrnament : AHazeActor
{
	FOnDarkCaveDragonSpiritFreed OnDarkCaveDragonSpiritFreed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EffectOrigin;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent)
	USummitDarkCaveSaveComponent SaveComp;

	UPROPERTY(EditAnywhere)
	TArray<AActor> Meshes;

	UPROPERTY()
	UMaterialInterface OnMaterial;

	bool bIsCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SaveComp.OnSummitDarkCaveActivateSave.AddUFunction(this, n"OnSummitDarkCaveActivateSave");
		for (AActor Mesh : Meshes)
		{
			Mesh.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION()
	private void OnSummitDarkCaveActivateSave()
	{
		ActivateDragonOrnament(false);
	}

	UFUNCTION()
	void ActivateDragonOrnament(bool bPlayEffect = true)
	{
		FDarkCaveOrnamentActivatedParams Params;
		Params.Location = EffectOrigin.WorldLocation;

		for (AActor Mesh : Meshes)
		{
			Mesh.SetActorHiddenInGame(false);
		}

		if (bPlayEffect)
			UDarkCaveDragonOrnamentEffectHandler::Trigger_OrnamentActivated(this, Params);
		bIsCompleted = true;
		OnDarkCaveDragonSpiritFreed.Broadcast();
	}

	UFUNCTION()
	void ActivateOrnamentEffect()
	{
		FDarkCaveOrnamentActivatedParams Params;
		Params.Location = EffectOrigin.WorldLocation;
		UDarkCaveDragonOrnamentEffectHandler::Trigger_OrnamentActivated(this, Params);
	}
};