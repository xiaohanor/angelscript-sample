class AIslandPunchotronArenaZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY()
	UMaterialInterface Material;

	UPROPERTY()
	UMaterialInterface BlueMaterial;

	UPROPERTY()
	UMaterialInstanceDynamic DynamicMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (UsableByPlayer == EHazePlayer::Zoe)
		{
			DynamicMaterial = Material::CreateDynamicMaterialInstance(this, BlueMaterial);
		}
		else
		{
			DynamicMaterial = Material::CreateDynamicMaterialInstance(this, Material);
		} 
		Mesh.SetMaterial(2, DynamicMaterial);
	}
};