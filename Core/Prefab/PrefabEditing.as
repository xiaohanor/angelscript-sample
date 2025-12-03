#if EDITORONLY_DATA
struct FPrefabState
{
	UPROPERTY()
	bool bEditable = false;
	UPROPERTY()
	TMap<FGuid, FString> EditableActorsInPrefab;
	UPROPERTY()
	TMap<int, FPrefabComponents> ComponentsInPrefab;
	UPROPERTY()
	FPrefabInstanceSettings InstanceSettings;
};

struct FPrefabInstanceSettings
{
	UPROPERTY(Category = "Prefab Instance Settings", Meta = (UIMin = "0.05", UIMax = "2", ClampMin = "0.05", ClampMax = "2"))
	float LightmapResolutionScale = 1.0;

	bool opEquals(FPrefabInstanceSettings Other) const
	{
		return
			LightmapResolutionScale == Other.LightmapResolutionScale
		;
	}
};

struct FPrefabComponents
{
	UPROPERTY()
	TMap<FGuid, FName> Components;
};

#endif

#if EDITOR
struct FPrefabUpdateResult
{
	FTransform OffsetTransform;
	int CurrentIndex = 0;

	TMap<FGuid, UActorComponent> ComponentsByGuid;
	TMap<UActorComponent, FGuid> GuidsByComponent;

	TMap<int, FPrefabComponents> ComponentsInPrefab;

	void UsedComponent(FGuid Guid, UActorComponent Component)
	{
		ComponentsByGuid.Add(Guid, Component);
		GuidsByComponent.Add(Component, Guid);

		ComponentsInPrefab.FindOrAdd(CurrentIndex).Components.Add(Guid, Component.GetName());
	}
};

struct FPrefabEditResult
{
	TMap<AActor, FGuid> PendingAttachments;

	void Attach(AActor Actor, FGuid AttachGuid)
	{
		if (AttachGuid.IsValid())
			PendingAttachments.Add(Actor, AttachGuid);
	}
};

namespace Prefab
{

const int PREFAB_GLOBAL_VERSION = 1;

bool NeedsPrefabUpdate(UPrefabAsset PrefabAsset, FGuid LastUpdatedGuid)
{
	return LastUpdatedGuid != Prefab::GetUpdatedPrefabChangeId(PrefabAsset);
}

FGuid GetUpdatedPrefabChangeId(UPrefabAsset PrefabAsset)
{
	if (PrefabAsset == nullptr)
		return FGuid();

	// Check if any of our child prefabs have changed, which means we have to bump
	// our own ChangeId as well.
	int ChildCount = PrefabAsset.Data.ChildPrefabs.Num();
	if (PrefabAsset.ChildPrefabChangeIds.Num() != ChildCount)
	{
		BumpPrefabChangeId(PrefabAsset);
	}
	else
	{
		for (int i = 0; i < ChildCount; ++i)
		{
			FGuid ChildChangeId = Prefab::GetUpdatedPrefabChangeId(PrefabAsset.Data.ChildPrefabs[i].PrefabAsset);
			if (ChildChangeId != PrefabAsset.ChildPrefabChangeIds[i])
			{
				BumpPrefabChangeId(PrefabAsset);
				break;
			}
		}
	}

	FGuid ChangeId = PrefabAsset.ChangeId;
	ChangeId[0] = PREFAB_GLOBAL_VERSION;

	return ChangeId;
}

void BumpPrefabChangeId(UPrefabAsset PrefabAsset)
{
	PrefabAsset.Modify();
	PrefabAsset.ChangeId = FGuid::NewGuid();
	PrefabAsset.ChangeId[0] = PREFAB_GLOBAL_VERSION;
	PrefabAsset.ChildPrefabChangeIds.Reset();
	for (FPrefabChildPrefab Child : PrefabAsset.Data.ChildPrefabs)
		PrefabAsset.ChildPrefabChangeIds.Add(GetUpdatedPrefabChangeId(Child.PrefabAsset));
}

void UpdateAllChangedPrefabsInLevel()
{
	FScopeDebugEditorWorld ScopeEditorWorld;

	auto AllPrefabs = Editor::GetAllEditorWorldActorsOfClass(APrefabRoot);

	for (auto It : AllPrefabs)
	{
		auto Prefab = Cast<APrefabRoot>(It);
		Prefab.UpdatePrefabIfChanged();
	}
}

FPrefabData GatherDataFromEditablePrefab(APrefabRoot Prefab, FPrefabState& State)
{
	FAngelscriptGameThreadScopeWorldContext ScopeWorldContext(Prefab);

	if (!State.bEditable)
	{
		devErrorAlways("Cannot gather data from a preset that isn't editable.");
		return FPrefabData();
	}

	FTransform RootTransform = Prefab.ActorTransform;
	FPrefabData Data;

	// Data about the merged mesh should be kept
	if (Prefab.PrefabAsset != nullptr)
	{
		Data.MergedMeshSettings = Prefab.PrefabAsset.Data.MergedMeshSettings;
		Data.MergedMeshTransform = Prefab.PrefabAsset.Data.MergedMeshTransform;
	}

	// Find all props attached to this actor
	TArray<AActor> Attachments;
	GetDirectPrefabDescendants(Prefab, Prefab.RootComponent, Attachments);

	// All attached actors should have data saved for them
	for (AActor Actor : Attachments)
	{
		auto PropActor = Cast<AHazeProp>(Actor);
		if (PropActor != nullptr)
		{
			if (PropActor.PropSettings.StaticMesh == nullptr)
				continue;

			Data.Props.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, PropActor)
			);
		}

		auto ChildPrefabActor = Cast<APrefabRoot>(Actor);
		if (ChildPrefabActor != nullptr)
		{
			Data.ChildPrefabs.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, ChildPrefabActor)
			);
		}

		auto SpotLightActor = Cast<AHazeSpotLight>(Actor);
		if (SpotLightActor != nullptr)
		{
			Data.SpotLights.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, SpotLightActor)
			);
		}

		auto PointLightActor = Cast<AHazePointLight>(Actor);
		if (PointLightActor != nullptr)
		{
			Data.PointLights.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, PointLightActor)
			);
		}

		auto NiagaraActor = Cast<AHazeNiagaraActor>(Actor);
		if (NiagaraActor != nullptr)
		{
			Data.NiagaraSystems.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, NiagaraActor)
			);
		}

		auto SpotSound = Cast<APrefabSpotSound>(Actor);
		if (SpotSound != nullptr)
		{
			Data.SpotSounds.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, SpotSound)
			);
		}

		auto HazeSphere = Cast<AHazeSphere>(Actor);
		if (HazeSphere != nullptr)
		{
			Data.HazeSpheres.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, HazeSphere)
			);
		}

		auto PropLine = Cast<APropLine>(Actor);
		if (PropLine != nullptr)
		{
			Data.PropLines.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, PropLine)
			);
		}

		auto Decal = Cast<ADecalActor>(Actor);
		if (Decal != nullptr)
		{
			Data.Decals.Add(
				GatherDataFromEditablePrefabPart(Prefab, State, Decal)
			);
		}
	}
		
	return Data;
}

bool CheckActorsSupportPrefab(APrefabRoot Prefab, FPrefabState& State)
{
	TArray<AActor> Attachments;
	GetDirectPrefabDescendants(Prefab, Prefab.RootComponent, Attachments);

	TArray<FString> InvalidAttachments;
	for (AActor Actor : Attachments)
	{
		auto PropActor = Cast<AHazeProp>(Actor);
		if (PropActor != nullptr)
			continue;
		
		auto ChildPrefab = Cast<APrefabRoot>(Actor);
		if (ChildPrefab != nullptr)
			continue;

		auto Light = Cast<ALight>(Actor);
		if (Light != nullptr)
		{
			if (Light.LightComponent.Mobility != EComponentMobility::Static)
			{
				InvalidAttachments.Add(f"{Actor.GetActorLabel()} ({Actor.Class.Name}): Only Static lights are supported in prefabs");
				continue;
			}
		}

		auto Spotlight = Cast<ASpotLight>(Actor);
		if (Spotlight != nullptr)
			continue;

		auto Pointlight = Cast<APointLight>(Actor);
		if (Pointlight != nullptr)
			continue;

		auto NiagaraActor = Cast<AHazeNiagaraActor>(Actor);
		if (NiagaraActor != nullptr)
			continue;

		auto SpotSound = Cast<APrefabSpotSound>(Actor);
		if (SpotSound != nullptr)
			continue;

		auto Decal = Cast<ADecalActor>(Actor);
		if (Decal != nullptr)
			continue;

		auto HazeSphere = Cast<AHazeSphere>(Actor);
		if (HazeSphere != nullptr)
		{
			if (HazeSphere.HazeSphereComponent.Type == EFogVolume::Mesh)
			{
				InvalidAttachments.Add(f"{Actor.GetActorLabel()} ({Actor.Class.Name}): HazeSpheres of type Mesh are not supported");
			}
			continue;
		}

		auto PropLine = Cast<APropLine>(Actor);
		if (PropLine != nullptr)
			continue;

		InvalidAttachments.Add(f"{Actor.GetActorLabel()} ({Actor.Class.Name})");
	}

	if (InvalidAttachments.Num() != 0)
	{
		FString Message = f"Prefab actor {Prefab.GetActorLabel()} has actors attached that do not support saving to prefabs:\n";
		for (auto InvalidName : InvalidAttachments)
			Message += f"\n{InvalidName}";
		FMessageDialog::Open(EAppMsgType::Ok, FText::FromString(Message));
		return false;
	}

	return true;
}

void StartEditingPrefab(AActor Prefab, FPrefabData Data, FPrefabState& State)
{
	FAngelscriptGameThreadScopeWorldContext ScopeWorldContext(Prefab);
	FAngelscriptExcludeScopeFromLoopTimeout ScopeExcludeTimeout();

	if (State.bEditable)
	{
		devErrorAlways("Prefab is already editable.");
		return;
	}

	State.bEditable = true;

	FPrefabEditResult Result;

	// Destroy or hide all the permanent-only parts of the prefab
	for (auto CompList : State.ComponentsInPrefab)
	{
		for (auto PermanentComp : CompList.Value.Components)
		{
			auto Comp = UActorComponent::Get(Prefab, PermanentComp.Value);
			if (Comp == nullptr)
				continue;

			Comp.Modify();

			auto SceneComp = Cast<USceneComponent>(Comp);
			if (SceneComp != nullptr)
				SceneComp.SetVisibility(false);

			auto NiagaraComp = Cast<UNiagaraComponent>(Comp);
			if (NiagaraComp != nullptr)
				NiagaraComp.Deactivate();

			auto LightComp = Cast<ULightComponentBase>(Comp);
			if (LightComp != nullptr)
				Editor::UpdateLightComponentEditorSpriteSize(LightComp, 0.0);
		}
	}

	// Create editable actors for the parts of the prefab that aren't already actors
	for (const FPrefabProp& Prop : Data.Props)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, Prop.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, Prop);
	}

	for (const auto& PartData : Data.SpotLights)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, PartData.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, PartData);
	}

	for (const auto& PartData : Data.PointLights)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, PartData.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, PartData);
	}

	for (const auto& PartData : Data.NiagaraSystems)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, PartData.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, PartData);
	}

	for (const auto& PartData : Data.HazeSpheres)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, PartData.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, PartData);
	}

	for (const auto& PartData : Data.PropLines)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, PartData.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, PartData);
	}

	for (const auto& PartData : Data.SpotSounds)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, PartData.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, PartData);
	}

	for (const auto& PartData : Data.Decals)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, PartData.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, PartData);
	}

	for (const FPrefabChildPrefab& ChildPrefab : Data.ChildPrefabs)
	{
		auto Actor = GetEditableActorInPrefab(Prefab, State, ChildPrefab.Guid);
		if (Actor == nullptr)
			CreateEditablePrefabPart(Prefab, State, Result, ChildPrefab);
	}

	// If we have sub-attachments in our children, apply them now
	for (auto AttachElem : Result.PendingAttachments)
	{
		AActor Actor = AttachElem.Key;
		AActor Attachment = GetEditableActorInPrefab(Prefab, State, AttachElem.Value);

		if (Attachment != nullptr)
			Actor.AttachToActor(Attachment, NAME_None, EAttachmentRule::KeepWorld);
	}
}

void StopEditingPrefab(AActor Prefab, FPrefabData Data, FPrefabState& State)
{
	FAngelscriptGameThreadScopeWorldContext ScopeWorldContext(Prefab);
	FAngelscriptExcludeScopeFromLoopTimeout ScopeExcludeTimeout();

	if (!State.bEditable)
	{
		devErrorAlways("Prefab is already not editable.");
		return;
	}

	TArray<AActor> EditableActors;
	for (auto ActorElem : State.EditableActorsInPrefab)
	{
		AActor Actor = GetEditableActorInPrefab(Prefab, State, ActorElem.Key);
		if (Actor != nullptr)
			EditableActors.Add(Actor);
	}

	for (auto Actor : EditableActors)
		Actor.DestroyActor();

	State.EditableActorsInPrefab.Reset();
	State.bEditable = false;

	UpdatePrefabToData(Prefab, Data, State);
}

TSet<UActorComponent> GetAllPreviousPermanentPrefabComponents(AActor Prefab, FPrefabState& State)
{
	TArray<USceneComponent> ComponentsOnActor;
	Prefab.GetComponentsByClass(ComponentsOnActor);

	TSet<UActorComponent> PreviousComponents;
	for (auto Comp : ComponentsOnActor)
	{
		if (Comp.ComponentCreationMethod == EComponentCreationMethod::Instance
			&& Comp.IsVisualizationComponent())
		{
			PreviousComponents.Add(Comp);
		}
	}

	return PreviousComponents;
}

void UpdatePrefabToData(AActor Prefab, FPrefabData Data, FPrefabState& State)
{
	FAngelscriptGameThreadScopeWorldContext ScopeWorldContext(Prefab);
	FAngelscriptExcludeScopeFromLoopTimeout ScopeExcludeTimeout();

	if (State.bEditable)
	{
		devErrorAlways("Cannot update an editable prefab.");
		return;
	}

	// Remember which components we had before
	TSet<UActorComponent> PreviousComponents = GetAllPreviousPermanentPrefabComponents(Prefab, State);

	FPrefabUpdateResult Result;
	Result.CurrentIndex = 0;
	Result.OffsetTransform = FTransform::Identity;
	UpdatePrefabPartsFromData(Prefab, Data, State, Result);

	// Make all the components inside it visible
	for (auto CompElem : Result.GuidsByComponent)
	{
		CompElem.Key.Modify();
		auto NiagaraComp = Cast<UNiagaraComponent>(CompElem.Key);
		if (NiagaraComp != nullptr && NiagaraComp.GetAutoActivate())
			NiagaraComp.Activate();
		auto SceneComp = Cast<USceneComponent>(CompElem.Key);
		if (SceneComp != nullptr)
			SceneComp.SetVisibility(true);
	}

	// Delete old components and actors
	for (auto PrevComp : PreviousComponents)
	{
		if (!Result.GuidsByComponent.Contains(PrevComp))
			PrevComp.DestroyComponent(PrevComp);
	}

	State.ComponentsInPrefab = Result.ComponentsInPrefab;
}

void UpdatePrefabPartsFromData(AActor Prefab, FPrefabData Data, FPrefabState& State, FPrefabUpdateResult& Result)
{
	// Props should only be created if we aren't displaying a merged mesh
	if (Data.MergedMeshSettings.StaticMesh != nullptr)
	{
		UpdatePermanentMergedMesh(Prefab, State, Data, Result);
	}
	else
	{
		for (const FPrefabProp& Prop : Data.Props)
			UpdatePermanentPrefabPart(Prefab, State, Prop, Result);
	}

	for (const auto& PartData : Data.SpotLights)
		UpdatePermanentPrefabPart(Prefab, State, PartData, Result);

	for (const auto& PartData : Data.PointLights)
		UpdatePermanentPrefabPart(Prefab, State, PartData, Result);

	for (const auto& PartData : Data.NiagaraSystems)
		UpdatePermanentPrefabPart(Prefab, State, PartData, Result);

	for (const auto& PartData : Data.HazeSpheres)
		UpdatePermanentPrefabPart(Prefab, State, PartData, Result);

	for (const auto& PartData : Data.PropLines)
		UpdatePermanentPrefabPart(Prefab, State, PartData, Result);

	for (const auto& PartData : Data.SpotSounds)
		UpdatePermanentPrefabPart(Prefab, State, PartData, Result);

	for (const auto& PartData : Data.Decals)
		UpdatePermanentPrefabPart(Prefab, State, PartData, Result);

	// Update child prefabs recursively
	// NOTE: Child prefabs need to be at the end of this function because it will mess with the `CurrentIndex` value
	FTransform OriginalOffsetTransform = Result.OffsetTransform;

	for (const FPrefabChildPrefab& ChildPrefab : Data.ChildPrefabs)
	{
		FTransform ChildTransform = FTransform::ApplyRelative(OriginalOffsetTransform, ChildPrefab.Transform);
		Result.OffsetTransform = ChildTransform;
		Result.CurrentIndex += 1;

		if (ChildPrefab.PrefabAsset != nullptr)
			UpdatePrefabPartsFromData(Prefab, ChildPrefab.PrefabAsset.Data, State, Result);
	}

	Result.OffsetTransform = OriginalOffsetTransform;
}

void DestroyPermanentComponents(AActor Prefab, FPrefabState& State)
{
	TSet<UActorComponent> PreviousComponents = GetAllPreviousPermanentPrefabComponents(Prefab, State);
	for (auto Comp : PreviousComponents)
	{
		Comp.DestroyComponent(Comp);
	}

	State.ComponentsInPrefab.Reset();
}

FGuid GetOrCreateGuidForEditableActor(FPrefabState& State, AActor Actor)
{
	FString PathName = Actor.GetPathName();
	for (auto Elem : State.EditableActorsInPrefab)
	{
		if (Elem.Value == PathName)
			return Elem.Key;
	}

	FGuid NewGuid = FGuid::NewGuid();
	State.EditableActorsInPrefab.Add(NewGuid, PathName);
	return NewGuid;
}

void GetDirectPrefabDescendants(AActor Root, USceneComponent Component, TArray<AActor>& Attachments)
{
	if (Component.Owner != Root)
	{
		Attachments.AddUnique(Component.Owner);

		// Don't recurse further down child prefabs
		if (Component.Owner.IsA(APrefabRoot))
			return;
	}

	int NumChildren = Component.NumChildrenComponents;
	for (int i = 0; i < NumChildren; ++i)
	{
		auto ChildComp = Component.GetChildComponent(i);
		if (ChildComp != nullptr)
			GetDirectPrefabDescendants(Root, ChildComp, Attachments);
	}
}

bool IsStandardLabel(FString Label, FString StandardName)
{
	if (!Label.StartsWith(StandardName+" "))
		return false;
	FString Number = Label.Mid(StandardName.Len() + 1);
	if (Number.IsEmpty() || Number.IsNumeric())
		return true;
	return false;
}

AActor GetEditableActorInPrefab(AActor Prefab, FPrefabState State, FGuid Guid)
{
	FString EditableActor;
	State.EditableActorsInPrefab.Find(Guid, EditableActor);

	AActor Actor = Cast<AActor>(FindObject(nullptr, EditableActor));
	if (Actor != nullptr)
	{
		// If it's no longer attached to us, it no longer counts
		if (Actor.RootComponent == nullptr || !Actor.RootComponent.IsAttachedTo(Prefab.RootComponent))
		{
			return nullptr;
		}
	}

	return Actor;
}

UActorComponent GetPermanentPrefabComponent(AActor Prefab, FPrefabUpdateResult& Result, FPrefabState& State, FGuid Guid)
{
	FName ComponentName;
	if (State.ComponentsInPrefab.FindOrAdd(Result.CurrentIndex).Components.Find(Guid, ComponentName))
		return UActorComponent::Get(Prefab, ComponentName);
	else
		return nullptr;
}

UStaticMesh GenerateMergedMesh(APrefabRoot Prefab, FPrefabData Data, FPrefabState& State)
{
	TArray<UPrimitiveComponent> ComponentsToMerge;
	TArray<UObject> AssetsToSync;

	FMeshMergingSettings Settings;

	// Collect mesh components directly on the prefab
	if (!State.bEditable)
	{
		TArray<UStaticMeshComponent> MeshComps;
		Prefab.GetComponentsByClass(MeshComps);

		for (auto MeshComp : MeshComps)
			ComponentsToMerge.Add(MeshComp);
	}

	// Collect mesh components from actors attached to the prefab
	TArray<AActor> AttachedActors;
	GetDirectPrefabDescendants(Prefab, Prefab.RootComponent, AttachedActors);

	for (auto AttachedActor : AttachedActors)
	{
		// Don't collect meshes from child prefabs, they handle their own merging
		if (AttachedActor.IsA(APrefabRoot))
			continue;

		TArray<UStaticMeshComponent> MeshComps;
		AttachedActor.GetComponentsByClass(MeshComps);

		for (auto MeshComp : MeshComps)
			ComponentsToMerge.Add(MeshComp);
	}

	if (ComponentsToMerge.Num() == 0)
		return nullptr;

	// Make sure all LODs are considered, so we don't have to go in and edit the LODs for the merged mesh.
	Settings.LODSelectionType = EMeshLODSelectionType::AllLODs;
	Settings.bMergePhysicsData = true;
	Settings.bBakeVertexDataToMesh = true;

	FVector MergedLocation;
	FString AssetPath = f"/Game/Environment/Prefabs/MergedMeshes/{Prefab.PrefabAsset.Name}";

	Editor::MergeComponentsToStaticMesh(
		ComponentsToMerge,
		Prefab.GetWorld(),
		Settings,
		AssetPath,
		AssetsToSync,
		MergedLocation
	);

	for (UObject CreatedAsset : AssetsToSync)
	{
		// Make the Content Browser aware of our newly created assets,				
		AssetRegistry::AssetCreated(CreatedAsset);
	}

	if (AssetsToSync.Num() != 0)
	{
		auto StaticMesh = Cast<UStaticMesh>(AssetsToSync[0]);
		StaticMesh.Modify();

		return StaticMesh;
	}
	else
	{
		return nullptr;
	}
}

bool HasAttachments(APrefabRoot PrefabRoot)
{
	TArray<AActor> Attachments;
	Prefab::GetDirectPrefabDescendants(PrefabRoot, PrefabRoot.RootComponent, Attachments);
	return Attachments.Num() != 0;
}

bool HasUnsavedChanges(APrefabRoot PrefabRoot)
{
	if (!PrefabRoot.PrefabState.bEditable && !(PrefabRoot.PrefabAsset == nullptr && Prefab::HasAttachments(PrefabRoot)))
		return false;
	if (PrefabRoot.PrefabAsset == nullptr)
		return true;

	FPrefabData CurrentData = GatherDataFromEditablePrefab(PrefabRoot, PrefabRoot.PrefabState);
	return CurrentData.IsChanged(PrefabRoot.PrefabAsset.Data);
}

APrefabRoot GetAttachedPrefab(AActor Actor)
{
	AActor CheckActor = Actor;
	APrefabRoot Prefab = nullptr;
	while (CheckActor != nullptr)
	{
		auto CheckPrefab = Cast<APrefabRoot>(CheckActor);
		if (CheckPrefab != nullptr)
			Prefab = CheckPrefab;
		CheckActor = CheckActor.AttachParentActor;
	}

	return Prefab;
}

bool CanEditPrefabChildren(APrefabRoot PrefabRoot)
{
	return PrefabRoot.PrefabState.bEditable || PrefabRoot.PrefabAsset == nullptr;
}

};
#endif