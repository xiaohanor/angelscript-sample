class UAssetsWithInvalidDevAssetReferencesContentBrowserFilter : UHazeScriptContentBrowserFilter
{
	default Color = FLinearColor::Red;
	default FilterName = "Dependent on Developer Assets";
	default Tooltip = "Shows all assets that are incorrectly referencing developer-only assets.";
	default Category = "Developer Assets";

	UFUNCTION(BlueprintOverride)
	bool IsAllowedByFilter(FString ObjectPath, FString AssetClass, FName AssetName, FName PackageName, FName PackagePath) const
	{
		if (Editor::IsDeveloperOnlyPath(ObjectPath))
			return false;

		TArray<FName> Dependencies;
		Editor::GetAssetDependenciesNonEditorOnly(PackageName, Dependencies);

		for (FName Dependency : Dependencies)
		{
			FString DependencyPath = Dependency.ToString();
			if (Editor::IsDeveloperOnlyPath(DependencyPath))
			{
				if (EditorAsset::DoesAssetExist(DependencyPath))
				{
					// Make an exception for editor billboards, because these are usually just for visualization in editor
					if (DependencyPath.StartsWith("/Game/Editor/EditorBillboards/"))
						continue;
					return true;
				}
			}
		}

		return false;
	}
}

class UReferencedDevAssetContentBrowserFilter : UHazeScriptContentBrowserFilter
{
	default Color = FLinearColor::Red;
	default FilterName = "Developer Assets with References";
	default Tooltip = "Shows all developer-only assets that are incorrectly used within non-developer assets.";
	default Category = "Developer Assets";

	UFUNCTION(BlueprintOverride)
	bool IsAllowedByFilter(FString ObjectPath, FString AssetClass, FName AssetName, FName PackageName, FName PackagePath) const
	{
		if (!Editor::IsDeveloperOnlyPath(ObjectPath))
			return false;

		// Make an exception for editor billboards, because these are usually just for visualization in editor
		if (ObjectPath.StartsWith("/Game/Editor/EditorBillboards/"))
			return false;

		// Check if we have any dependencies to developer-only assets
		TArray<FName> Referencers;
		Editor::GetAssetReferencersNonEditorOnly(PackageName, Referencers);

		for (FName Referencer : Referencers)
		{
			FString ReferencerPath = Referencer.ToString();
			if (!Editor::IsDeveloperOnlyPath(ReferencerPath))
			{
				return true;
			}
		}

		return false;
	}
}