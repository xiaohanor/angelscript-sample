struct FIslandSupervisorEyeMaterials
{
	UPROPERTY()
	UMaterialInterface EyeMainMaterial;

	UPROPERTY()
	UMaterialInterface EyeRimMaterial;
}

class UIslandSupervisorData : UDataAsset
{
	UPROPERTY()
	FIslandSupervisorEyeMaterials DeactiveMaterials;

	UPROPERTY()
	FIslandSupervisorEyeMaterials NeutralMaterials;

	UPROPERTY()
	FIslandSupervisorEyeMaterials HappyMaterials;

	UPROPERTY()
	FIslandSupervisorEyeMaterials AngryMaterials;
}