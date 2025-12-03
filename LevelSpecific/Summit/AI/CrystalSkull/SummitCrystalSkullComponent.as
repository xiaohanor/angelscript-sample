class USummitCrystalSkullComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Area")
	ASummitCritterSwarmAreaActor Area;

	UPROPERTY(EditInstanceOnly, Category = "SpawnCritters")
	AHazeActorSpawnerBase CritterSpawner;

	UPROPERTY()
	UMaterialInterface ClosedEyesMaterial;

	UPROPERTY()
	int EyesMaterialIndex = 2;

	bool bIsVulnerable = false;
	UMaterialInterface DefaultEyesMaterial;
	UStaticMeshComponent Mesh;
	ASummitCritterSwarmAreaActor SpecifiedArea;
	UHazeActorRespawnableComponent RespawnComp;

	float LastEvadeTime;
	float LastAttackTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = UStaticMeshComponent::Get(Owner); 
		DefaultEyesMaterial = Mesh.GetMaterial(EyesMaterialIndex);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		SpecifiedArea = Area;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		ClearVulnerable();

		Area = SpecifiedArea;
		if (Area == nullptr)
		{
			USummitCritterSwarmAreaRegistry AreaRegistry = Game::GetSingleton(USummitCritterSwarmAreaRegistry);
			Area = AreaRegistry.GetBestArea(Cast<AHazeActor>(Owner), RespawnComp.SpawnParameters);
		}
	}

	bool IsAllowedLocation(FVector Location) const
	{
		if (Area == nullptr)
			return true;
		return Area.IsWithin(Location);
	}

	FVector ProjectToArea(FVector Location) const
	{
		if (IsAllowedLocation(Location))
			return Location;
		return Area.ProjectToArea(Location);
	}

	void SetVulnerable()
	{
		if (bIsVulnerable)
			return;

		bIsVulnerable = true;
		if (ClosedEyesMaterial != nullptr)
			Mesh.SetMaterial(EyesMaterialIndex, ClosedEyesMaterial);
	}

	void ClearVulnerable()
	{
		if (!bIsVulnerable)
			return;

		bIsVulnerable = false;
		Mesh.SetMaterial(EyesMaterialIndex, DefaultEyesMaterial);
	}
}
