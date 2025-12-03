class ASummitDarkCaveSymbolManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5));
#endif

	UPROPERTY(DefaultComponent)
	USummitDarkCaveSaveComponent SaveComp;

	UPROPERTY(EditAnywhere)
	TArray<AActor> SymbolArray;
	TArray<UStaticMeshComponent> Meshes;
	TArray<UMaterialInstanceDynamic> DynamicMaterials;

	UPROPERTY(EditInstanceOnly)
	ADarkCaveSpiritStatue CrystalEgg;

	FLinearColor Color;
	float EmissiveMultiplier;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		for (AActor Actor : SymbolArray)
		{
			auto Mesh = UStaticMeshComponent::Get(Actor);
			DynamicMaterials.Add(Mesh.CreateDynamicMaterialInstance(0)); 
			Meshes.Add(Mesh);
		}

		Color = DynamicMaterials[0].GetVectorParameterValue(n"Tint_D_Emissive");
		for (UMaterialInstanceDynamic& Material : DynamicMaterials)
			Material.SetVectorParameterValue(n"Tint_D_Emissive", Color * EmissiveMultiplier);

	
		CrystalEgg.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
		SaveComp.OnSummitDarkCaveActivateSave.AddUFunction(this, n"OnSummitDarkCaveActivateSave");
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		SetActorTickEnabled(true);
		USummitDarkCaveSymbolManagerEventHandler::Trigger_OnDarkCaveSmybolLightUp(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		EmissiveMultiplier = Math::FInterpConstantTo(EmissiveMultiplier, 10.0, DeltaSeconds, 3.0);

		for (UMaterialInstanceDynamic& Material : DynamicMaterials)
		{
			Material.SetVectorParameterValue(n"Tint_D_Emissive", Color * EmissiveMultiplier);
		}
	}

	UFUNCTION()
	private void OnSummitDarkCaveActivateSave()
	{
		for (UMaterialInstanceDynamic& Material : DynamicMaterials)
		{
			Material.SetVectorParameterValue(n"Tint_D_Emissive", Color * 10.0);
		}
		USummitDarkCaveSymbolManagerEventHandler::Trigger_OnDarkCaveSmybolLightUp(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for (AActor Actor : SymbolArray)
		{
			if (Actor != nullptr)
				Debug::DrawDebugLine(ActorLocation, Actor.ActorLocation, FLinearColor::LucBlue, 5.0);
		}
	
		if (CrystalEgg != nullptr)
			Debug::DrawDebugLine(ActorLocation, CrystalEgg.ActorLocation, FLinearColor::Blue, 5.0);
	}
#endif
};