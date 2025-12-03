
UCLASS(HideCategories = "Rendering Replication Collision Debug Input HLOD Actor LOD Cooking DataLayers WorldPartition Physics LevelInstance", Meta = (NoSourceLink, DisplayName = "Prefab"))
class APrefabRoot : AHazeBasePrefab
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.RelativeLocation = FVector(0.0, 0.0, 50.0);
	default EditorIcon.RelativeScale3D = FVector(0.5, 0.5, 0.5);
	default EditorIcon.SpriteName = "Prefab";
#endif

#if EDITORONLY_DATA
	UPROPERTY(EditInstanceOnly, Category = "Prefab")
	UPrefabAsset PrefabAsset;

	UPROPERTY(EditInstanceOnly, Category = "HiddenPrefabState")
	FPrefabState PrefabState;

	UPROPERTY(EditInstanceOnly, Category = "Instance Settings", Meta = (ShowOnlyInnerProperties))
	FPrefabInstanceSettings InstanceSettings;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// TEMP: Clear the editor-only flag on all the permanent components on the actor.
		// It has been set incorrectly before because IsVisualizationComponent flags it automatically.
		TArray<UHazePropComponent> Props;
		GetComponentsByClass(Props);
		for (auto Comp : Props)
			Comp.bIsEditorOnly = false;

		TArray<USpotLightComponent> Spotlights;
		GetComponentsByClass(Spotlights);
		for (auto Comp : Spotlights)
			Comp.bIsEditorOnly = false;

		TArray<UPointLightComponent> Pointlights;
		GetComponentsByClass(Pointlights);
		for (auto Comp : Pointlights)
			Comp.bIsEditorOnly = false;

#if COOK_COMMANDLET
		// TEMP: Fix haze spheres on prefabs that don't have the correct materials set
		TArray<UHazeSphereComponent> HazeSpheres;
		GetComponentsByClass(HazeSpheres);
		for (auto Comp : HazeSpheres)
			Comp.Cook_LoadHazeSphereMaterials();
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	UHazeBasePrefabAsset GetUsedAsset() const
	{
		return PrefabAsset;
	}

	void UpdatePrefabIfChanged()
	{
		if (PrefabAsset == nullptr)
			return;
		if (PrefabState.bEditable)
			return;
		if (!Prefab::NeedsPrefabUpdate(PrefabAsset, LastUpdatedGuid))
			return;
		Modify();
		UpdatePrefabToData();
	}

	void UpdatePrefabToData()
	{
		PrefabState.InstanceSettings = InstanceSettings;
		if (PrefabAsset == nullptr)
		{
			Prefab::UpdatePrefabToData(this, FPrefabData(), PrefabState);
			LastUpdatedGuid = FGuid();
		}
		else
		{
			Prefab::UpdatePrefabToData(this, PrefabAsset.Data, PrefabState);
			LastUpdatedGuid = Prefab::GetUpdatedPrefabChangeId(PrefabAsset);
		}
	}

	void StartEditing()
	{
		if (PrefabAsset == nullptr)
			return;
		Prefab::StartEditingPrefab(this, PrefabAsset.Data, PrefabState);
	}

	void DiscardChangesAndStopEditing()
	{
		if (PrefabAsset != nullptr)
			Prefab::StopEditingPrefab(this, PrefabAsset.Data, PrefabState);
		else
			Prefab::StopEditingPrefab(this, FPrefabData(), PrefabState);
	}

	void SaveChangesAndStopEditing()
	{
		if (!Prefab::CheckActorsSupportPrefab(this, PrefabState))
			return;

		FPrefabData NewData = Prefab::GatherDataFromEditablePrefab(this, PrefabState);
		bool bNewAsset = false;
		bool bChangedPrefab = false;

		// Prompt for saving a prefab asset if we don't have one
		if (PrefabAsset == nullptr)
		{
			PrefabAsset = UPrefabAsset();
			PrefabAsset.Data = NewData;
			Prefab::BumpPrefabChangeId(PrefabAsset);
			bNewAsset = true;
			bChangedPrefab = true;
		}
		else
		{
			if (NewData.IsChanged(PrefabAsset.Data))
			{
				PrefabAsset.Modify();
				PrefabAsset.Data = NewData;
				Prefab::BumpPrefabChangeId(PrefabAsset);
				bChangedPrefab = true;
			}
			else
			{
				Prefab::GetUpdatedPrefabChangeId(PrefabAsset);
			}
		}

		// If we created a new asset make sure to save it
		if (bNewAsset)
		{
			PrefabAsset = Cast<UPrefabAsset>(Editor::SaveAssetAsNewPath(PrefabAsset));
			if (PrefabAsset == nullptr)
				return;
		}

		// Update the merged mesh
		if (PrefabAsset.bAutoGenerateMergedMesh)
		{
			if (bChangedPrefab || PrefabAsset.Data.MergedMeshSettings.StaticMesh == nullptr)
			{
				if (bNewAsset)
					PrefabAsset.Modify();
				PrefabAsset.Data.MergedMeshSettings.StaticMesh = Prefab::GenerateMergedMesh(this, PrefabAsset.Data, PrefabState);
				Prefab::BumpPrefabChangeId(PrefabAsset);
			}
		}
		else
		{
			if (PrefabAsset.Data.MergedMeshSettings.StaticMesh != nullptr)
			{
				PrefabAsset.Modify();
				PrefabAsset.Data.MergedMeshSettings.StaticMesh = nullptr;
				Prefab::BumpPrefabChangeId(PrefabAsset);
			}
		}

		// Stop editing
		if (PrefabAsset != nullptr)
		{
			Prefab::StopEditingPrefab(this, PrefabAsset.Data, PrefabState);
			LastUpdatedGuid = Prefab::GetUpdatedPrefabChangeId(PrefabAsset);
		}
		else
		{
			Prefab::StopEditingPrefab(this, FPrefabData(), PrefabState);
			LastUpdatedGuid = FGuid();
		}

		// Trigger an unreal save as well
		if (bNewAsset || bChangedPrefab)
		{
			TArray<UPackage> Packages;
			Packages.Add(PrefabAsset.GetOutermost());

			FSourceControlState FileInfo = SourceControl::QueryFileState(Packages[0].GetName().ToString());
			if (FileInfo.bIsUnknown || (!FileInfo.bIsCheckedOut && !FileInfo.bIsAdded))
				UEditorLoadingAndSavingUtils::SavePackagesWithDialog(Packages, true);
			else
				UEditorLoadingAndSavingUtils::SavePackages(Packages, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPlacedPrefab(UHazeBasePrefabAsset Asset, bool bIsDropPreview)
	{
		PrefabAsset = Cast<UPrefabAsset>(Asset);
		UpdatePrefabToData();
	}

	UFUNCTION(BlueprintOverride)
	void OnCreateThumbnail(UHazeBasePrefabAsset Asset)
	{
		PrefabAsset = Cast<UPrefabAsset>(Asset);
		if (EditorIcon != nullptr)
			EditorIcon.DestroyComponent(EditorIcon);
		UpdatePrefabToData();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (PrefabState.bEditable)
			return;

		if (InstanceSettings != PrefabState.InstanceSettings)
			UpdatePrefabToData();
	}
	
#endif
};