class URenameAssetsActions : UScriptEditorMenuExtension
{
	default ExtensionPoint = n"ContentBrowser.AssetContextMenu.AssetActionsSubMenu";

	/**
	 * Replace a substring in the asset names of all selected assets.
	 */
	UFUNCTION(CallInEditor)
	void RenameAssets_ReplaceString(FString FindSubstring, FString ReplaceWith)
	{
		FString Message = "The following files will be renamed:\n\n";

		auto Assets = EditorUtility::GetSelectedAssetData();
		for (auto Asset : Assets)
		{
			FString NewName = Asset.AssetName.ToString();
			NewName = NewName.Replace(FindSubstring, ReplaceWith);

			if (NewName == Asset.AssetName.ToString())
				continue;

			Message += f"{Asset.AssetName} → {NewName}\n";
		}

		auto Result = FMessageDialog::Open(EAppMsgType::YesNo, FText::FromString(Message));
		if (Result == EAppReturnType::No)
			return;

		for (auto Asset : Assets)
		{
			FString NewName = Asset.AssetName.ToString();
			NewName = NewName.Replace(FindSubstring, ReplaceWith);

			if (NewName == Asset.AssetName.ToString())
				continue;

			FString NewPath = FPaths::GetPath(Asset.PackageName.ToString()) + "/" + NewName;
			EditorAsset::RenameAsset(Asset.PackageName.ToString(), NewPath);
		}
	}
}