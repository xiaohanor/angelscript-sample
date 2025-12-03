class UDeprecateAsset : UScriptEditorMenuExtension
{
	default ExtensionPoint = n"ContentBrowser.AssetContextMenu.AssetActionsSubMenu";

	/**
	 * Move the asset to the deprecated folder
	 */
	UFUNCTION(CallInEditor)
	void Deprecated_Assets()
	{
		FString Message = "The following files will be deprecated:\n\n";

		auto Assets = EditorUtility::GetSelectedAssetData();
		for (auto Asset : Assets)
		{
			Message += f"{Asset.AssetName.ToString()}\n";
		}

		auto Result = FMessageDialog::Open(EAppMsgType::YesNo, FText::FromString(Message));
		if (Result == EAppReturnType::No)
			return;

		for (auto Asset : Assets)
		{
			// Move the asset to the depricated folder, will raise data validation issues when attempting dev assets.
			FString NewName = Asset.AssetName.ToString();
			FString NewPath = "/Game/Environment/Depricated" + "/" + Asset.AssetName.ToString();
			EditorAsset::RenameAsset(Asset.PackageName.ToString(), NewPath);
		}
	}
}