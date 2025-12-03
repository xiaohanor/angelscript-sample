class UDeveloperContentValidator : UEditorValidatorBase
{
	UFUNCTION(BlueprintOverride)
	bool CanValidateAsset(UObject InAsset) const
	{
		return InAsset.IsA(UNiagaraSystem)
			|| InAsset.IsA(UMaterial)
			|| InAsset.IsA(UMaterialInstanceConstant)
			|| InAsset.IsA(UStaticMesh)
			|| InAsset.IsA(USkeletalMesh)
			|| InAsset.IsA(UBlueprint)
			|| InAsset.IsA(UDataAsset)
			|| InAsset.IsA(UWorld)
		;
	}

	UFUNCTION(BlueprintOverride)
	EDataValidationResult ValidateLoadedAsset(UObject InAsset)
	{
		// If the asset itself is a developer asset, we don't do any of these checks
		if (Editor::IsDeveloperOnlyPath(InAsset.GetPathName()))
		{
			AssetPasses(InAsset);
			return EDataValidationResult::Valid;
		}

		// Check if we have any dependencies to developer-only assets
		TArray<FName> Dependencies;
		Editor::GetAssetDependenciesNonEditorOnly(InAsset.Package.Name, Dependencies);

		for (FName Dependency : Dependencies)
		{
			FString DependencyPath = Dependency.ToString();
			if (Editor::IsDeveloperOnlyPath(DependencyPath))
			{
				// Make an exception for editor billboards, because these are usually just for visualization in editor
				if (DependencyPath.StartsWith("/Game/Editor/EditorBillboards/"))
					continue;

				// Dependency is not allowed, fail the asset validation
				if (EditorAsset::DoesAssetExist(DependencyPath))
				{
					AssetFails(InAsset, 
						FText::FromString(f"Non-developer asset has a dependency on developer-only asset {Dependency}"));
				}
			}
			else if (Editor::IsDeprecatedAssetPath(DependencyPath) && !Editor::IsDeprecatedAssetPath(InAsset.GetPathName()))
			{
				// Dependency is not allowed, fail the asset validation
				if (EditorAsset::DoesAssetExist(DependencyPath))
				{
					AssetFails(InAsset, 
						FText::FromString(f"Asset has a dependency on deprecated asset {Dependency}"));
				}
			}
		}

		// If we are a blueprint, make sure our class isn't a developer-only script class
		if (InAsset.IsA(UBlueprint))
		{
			UBlueprint Blueprint = Cast<UBlueprint>(InAsset);

			UClass ParentClass = Blueprint.GeneratedClass;
			while (ParentClass != nullptr && ParentClass.IsA(UBlueprintGeneratedClass))
				ParentClass = ParentClass.SuperClass;

			auto ScriptClass = Cast<UASClass>(ParentClass);
			if (ScriptClass != nullptr && ScriptClass.IsDeveloperOnly())
			{
				AssetFails(InAsset, 
					FText::FromString(f"Non-developer blueprint has developer-only parent class {ScriptClass.Name}"));
			}
		}

		if (GetValidationResult() == EDataValidationResult::Invalid)
			return EDataValidationResult::Invalid;

		AssetPasses(InAsset);
		return EDataValidationResult::Valid;
	}
}