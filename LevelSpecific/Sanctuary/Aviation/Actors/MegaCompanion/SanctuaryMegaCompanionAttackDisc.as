UCLASS(Abstract)
class ASanctuaryMegaCompanionAttackDisc : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshVFX;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance LightMaterial;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance DarkMaterial;

	float MeshRadius = 55.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshVFX.SetVisibility(false, true);
	}

	void SetIsLight(bool bIsLight)
	{
		if (bIsLight && LightMaterial != nullptr)
		{
			MeshVFX.SetMaterial(0, LightMaterial);
			MeshVFX.SetMaterial(1, LightMaterial);
		}
		if (!bIsLight && DarkMaterial != nullptr)
		{
			MeshVFX.SetMaterial(0, DarkMaterial);
			MeshVFX.SetMaterial(1, DarkMaterial);
		}
	}
};