class UHazeTextureActionUtility : UScriptAssetMenuExtension
{
	default SupportedClasses.Add(UTexture2D);

	// Get the first selected Texture2D, should not fail if we only call it through this action util
	// as it only allows to run with them selected.
	UTexture2D GetFirstSelected() {
		UTexture2D Texture;
		for (UObject Asset : EditorUtility::GetSelectedAssets() ) {
			Texture = Cast<UTexture2D>(Asset);
			if (Texture != nullptr)
				break;
		}
		return Texture;
	}

	// Given a Material that accepts a "Texture" texture parameter, render the material to a render target
	// and open a save dialog to store the rendered output
	void Render(UTexture2D Texture, UMaterialInterface Parent) {
		UMaterialInstanceDynamic MaterialInstance = Material::CreateDynamicMaterialInstance(nullptr, Parent);
		MaterialInstance.SetTextureParameterValue(n"Texture", Texture);

		UTextureRenderTarget2D RenderTarget = Rendering::CreateRenderTarget2D(
			Width = Texture.Blueprint_GetSizeX(),
			Height = Texture.Blueprint_GetSizeY(),
		);

		Rendering::DrawMaterialToRenderTarget(RenderTarget, MaterialInstance);
		UTexture2D Result = Rendering::RenderTargetCreateStaticTexture2DEditorOnly(RenderTarget, "Result");
		Editor::SaveAssetAsNewPath(Result);
		EditorAsset::DeleteAsset(Result.GetPathName());  // Delete the "original" asset in /Engine/...
	}

	// Fix normal maps with black background
	UFUNCTION(CallInEditor, Category = "Normal Map")
	void BlackToBlue()
	{
		UTexture2D Texture = GetFirstSelected();
		UMaterialInterface Parent = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/Materials/M_BlackToFlatNormals.M_BlackToFlatNormals"));
		Render(Texture, Parent);
	}

	// From a texture, create a mask where black values are made 
	UFUNCTION(CallInEditor)
	void CreateOpacity()
	{
		UTexture2D Texture = GetFirstSelected();
		UMaterialInterface Parent = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/Materials/M_CreateOpacity.M_CreateOpacity"));
		Render(Texture, Parent);
	}

	UFUNCTION(CallInEditor)
	void FlipVertical()
	{
		UTexture2D Texture = GetFirstSelected();
		EditorRendering::FlipTextureAssetVertically(Texture);
		Texture.MarkPackageDirty();
	}
}