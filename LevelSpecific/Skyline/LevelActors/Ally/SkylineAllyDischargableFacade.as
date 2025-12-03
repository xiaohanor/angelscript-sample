class ASkylineAllyDischargableFacade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	UMaterialInstance ChargedMaterial;

	UPROPERTY(DefaultComponent)
	USceneComponent BuildingRoot;

	UPROPERTY(EditAnywhere)
	UMaterialInstance HalfChargedMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInstance DischargedMaterial;

	UPROPERTY(EditAnywhere)
	float ChangeStateDuration = 1.0;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	TArray<UStaticMeshComponent> MeshComps;

	TArray<USpotLightComponent> SpotLights;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");

		BuildingRoot.GetChildrenComponentsByClass(UStaticMeshComponent, true, MeshComps);
		Root.GetChildrenComponentsByClass(USpotLightComponent, true, SpotLights);
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		for (auto Mesh : MeshComps)
			Mesh.SetMaterial(1, HalfChargedMaterial);
		
		Timer::ClearTimer(this, n"SetDischargedMaterial");
		Timer::SetTimer(this, n"SetChargedMaterial", ChangeStateDuration);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		for (auto Mesh : MeshComps)	
		Mesh.SetMaterial(1, HalfChargedMaterial);
		
		Timer::ClearTimer(this, n"SetChargedMaterial");
		Timer::SetTimer(this, n"SetDischargedMaterial", ChangeStateDuration);
	}

	UFUNCTION()
	private void SetChargedMaterial()
	{
		for (auto Mesh : MeshComps)
			Mesh.SetMaterial(1, ChargedMaterial);

		for (auto SpotLight : SpotLights)
			SpotLight.SetHiddenInGame(false);
	}

	UFUNCTION()
	private void SetDischargedMaterial()
	{
		for (auto Mesh : MeshComps)
			Mesh.SetMaterial(1, DischargedMaterial);	

		for (auto SpotLight : SpotLights)
			SpotLight.SetHiddenInGame(true);
	}
};