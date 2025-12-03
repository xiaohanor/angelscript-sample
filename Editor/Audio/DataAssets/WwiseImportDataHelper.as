
// Child class in AS so we can access UHazeVoxCharacterTemplate from Ak modules.
class UWwiseImportGroupsDataAsset : UHazeAudioWwiseImportGroupsDataAsset
{
	#if EDITOR
	
	UFUNCTION()
	TArray<FString> GetImportTags() const
	{
		auto Assets = Editor::LoadAllAssetsByClass(UHazeAudioWwiseImportSettings);
		TArray<FString> Names;
		for (const auto Asset: Assets)
		{
			FString AssetName = Asset.GetName().ToString();
			AssetName.RemoveFromStart("TTS_");
			AssetName.RemoveFromEnd("_Import");

			Names.Add(AssetName);
		}

		return Names;
	}

	UFUNCTION()
	TArray<FString> GetTemplateNames()
	{
		auto Assets = Editor::LoadAllAssetsByClass(UHazeVoxCharacterTemplate);
		TArray<FString> Names;
		for (const auto Asset: Assets)
		{
			auto Template = Cast<UHazeVoxCharacterTemplate>(Asset);
			if (Template == nullptr)
				continue;

			Names.Add(Template.CharacterName.ToString());
		}

		return Names;
	}

	#endif
}