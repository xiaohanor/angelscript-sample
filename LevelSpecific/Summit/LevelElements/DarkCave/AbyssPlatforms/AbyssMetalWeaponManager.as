class AAbyssMetalWeaponManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5));
#endif

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem SpawnEffectSystem;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ANightQueenMetal> MetalToSpawnClass;

	UPROPERTY(EditInstanceOnly)
	AAcidStatue AcidStatue;

	TArray<FTransform> MetalTransformArray;
	TArray<ANightQueenMetal> MetalWeapons;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Attached : AttachedActors)
		{
			ANightQueenMetal Weapon = Cast<ANightQueenMetal>(Attached);
			if (Weapon == nullptr)
				continue;
			MetalTransformArray.Add(Weapon.ActorTransform);
			Weapon.AddActorDisable(this);
		}	

		AcidStatue.OnCraftTempleAcidStatueActivated.AddUFunction(this, n"OnCraftTempleAcidStatueActivated");
		AcidStatue.OnCraftTempleAcidStatueDeactivated.AddUFunction(this, n"OnCraftTempleAcidStatueDeactivated");
	}

	UFUNCTION()
	private void OnCraftTempleAcidStatueActivated()
	{
		for (FTransform Transform : MetalTransformArray)
		{
			auto Weapon = Cast<ANightQueenMetal>(SpawnActor(MetalToSpawnClass, 
			Transform.Location, 
			Transform.Rotation.Rotator()));
			MetalWeapons.AddUnique(Weapon);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffectSystem, Transform.Location);
		}
	}

	UFUNCTION()
	private void OnCraftTempleAcidStatueDeactivated()
	{
		for (ANightQueenMetal Weapon : MetalWeapons)
		{
			if (!Weapon.bMelted)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffectSystem, Weapon.ActorLocation);
			Weapon.DestroyActor();
		}
		MetalWeapons.Empty();
	}
};