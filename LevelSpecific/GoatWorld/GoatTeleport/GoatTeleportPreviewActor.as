class AGoatTeleportPreviewActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PreviewRoot;

	UPROPERTY(DefaultComponent, Attach = PreviewRoot)
	UStaticMeshComponent PreviewMesh;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ValidMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface InvalidMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviewMesh.SetRenderedForPlayer(Game::Zoe, false);
	}

	void ActivatePreview()
	{
		SetActorHiddenInGame(false);
	}

	void DeactivatePreview()
	{
		SetActorHiddenInGame(true);
	}

	void SetPreviewValidity(bool bValid)
	{
		UMaterialInterface Mat = bValid ? ValidMaterial : InvalidMaterial;

		for (int i = 0; i < PreviewMesh.GetNumMaterials(); i++)
			PreviewMesh.SetMaterial(i, Mat);
	}
}