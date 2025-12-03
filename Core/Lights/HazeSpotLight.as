UCLASS(Meta = (NoSourceLink, DisplayName = "Spot Light", DefaultActorLabel = "Spot Light", HideCategories = "Navigation DataLayers AssetUserData Actor Tags Cooking Debug RayTracing", HighlightPlacement))
class AHazeSpotLight : ASpotLight
{
	// Size of the billboard sprite shown for the light in the editor
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Rendering")
	float EditorBillboardScale = 1.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		Editor::UpdateEditorSpriteSize(this, EditorBillboardScale);
#endif
	}
};