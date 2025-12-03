UCLASS(Meta = (NoSourceLink, DisplayName = "Point Light", DefaultActorLabel = "Point Light", HideCategories = "Navigation DataLayers AssetUserData Actor Tags Cooking Debug RayTracing", HighlightPlacement))
class AHazePointLight : APointLight
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