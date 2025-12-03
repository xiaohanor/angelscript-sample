UCLASS(Abstract)
class UChapterImageWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage Image;

	TSoftObjectPtr<UTexture2D> ActiveTexture;

	void SetChapterImage(TSoftObjectPtr<UTexture2D> Texture)
	{
		if (Texture == ActiveTexture)
			return;

		if (Texture.IsNull())
		{
			ActiveTexture = Texture;

			UMaterialInstanceDynamic DynamicMaterial = Image.GetDynamicMaterial();
			DynamicMaterial.SetTextureParameterValue(n"ChapterImage", nullptr);
			return;
		}

		ActiveTexture = Texture;
		Texture.LoadAsync(FOnSoftObjectLoaded(this, n"OnLoadedTexture"));
	}

	UFUNCTION()
	private void OnLoadedTexture(UObject LoadedObject)
	{
		UTexture2D Texture = Cast<UTexture2D>(LoadedObject);
		if (Texture == nullptr)
			return;

		if (ActiveTexture.Get() == LoadedObject)
		{
			UMaterialInstanceDynamic DynamicMaterial = Image.GetDynamicMaterial();
			DynamicMaterial.SetTextureParameterValue(n"ChapterImage", Texture);
		}
	}
}