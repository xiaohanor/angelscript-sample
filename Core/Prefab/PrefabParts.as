#if EDITOR
namespace Prefab
{

const FGuid GUID_MergedMesh(265, 8827, 22527, 1234);

FPrefabSpotLight GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, AHazeSpotLight Actor)
{
	FPrefabSpotLight SpotLight;
	SpotLight.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	SpotLight.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	SpotLight.SetFromLight(Actor.SpotLightComponent);
	SpotLight.EditorBillboardScale = Actor.EditorBillboardScale;

	if (Actor.AttachParentActor != Prefab)
		SpotLight.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);
	return SpotLight;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabSpotLight Data)
{
	AHazeSpotLight Actor = AHazeSpotLight::Spawn(Level = Prefab.GetLevel());

	Actor.EditorBillboardScale = Data.EditorBillboardScale;
	Editor::UpdateEditorSpriteSize(Actor, Data.EditorBillboardScale);

	Actor.SpotLightComponent.SetMobility(EComponentMobility::Movable);
	Data.Editor_AssignToLight(Actor.SpotLightComponent);
	Actor.SpotLightComponent.SetMobility(EComponentMobility::Static);

	Actor.AttachToActor(Prefab);
	Actor.SetActorRelativeTransform(Data.Transform);

	State.EditableActorsInPrefab.Add(Data.Guid, Actor.GetPathName());
	Result.Attach(Actor, Data.AttachedTo);
}

void UpdatePermanentPrefabPart(AActor Prefab, FPrefabState& State, FPrefabSpotLight Data, FPrefabUpdateResult& Result)
{
	USpotLightComponent Comp = Cast<USpotLightComponent>(GetPermanentPrefabComponent(Prefab, Result, State, Data.Guid));
	if (Comp == nullptr)
		Comp = Editor::AddInstanceComponentInEditor(Prefab, USpotLightComponent, NAME_None);

	Comp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Data.Transform));
	Comp.IsVisualizationComponent = true;
	Comp.bIsEditorOnly = false;

	FPrefabSpotLight CurrentData;
	CurrentData.SetFromLight(Comp);

	Editor::UpdateLightComponentEditorSpriteSize(Comp, 0.5 * Data.EditorBillboardScale);

	if (Data.IsChanged(CurrentData))
	{
		Comp.SetMobility(EComponentMobility::Movable);
		Data.Editor_AssignToLight(Comp);
		Comp.SetMobility(EComponentMobility::Static);
	}

	Result.UsedComponent(Data.Guid, Comp);
}

FPrefabPointLight GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, AHazePointLight Actor)
{
	FPrefabPointLight PointLight;
	PointLight.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	PointLight.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	PointLight.SetFromLight(Actor.PointLightComponent);
	PointLight.EditorBillboardScale = Actor.EditorBillboardScale;

	if (Actor.AttachParentActor != Prefab)
		PointLight.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);
	return PointLight;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabPointLight Data)
{
	AHazePointLight Actor = AHazePointLight::Spawn(Level = Prefab.GetLevel());

	Actor.EditorBillboardScale = Data.EditorBillboardScale;
	Editor::UpdateEditorSpriteSize(Actor, Data.EditorBillboardScale);

	Actor.PointLightComponent.SetMobility(EComponentMobility::Movable);
	Data.Editor_AssignToLight(Actor.PointLightComponent);
	Actor.PointLightComponent.SetMobility(EComponentMobility::Static);

	Actor.AttachToActor(Prefab);
	Actor.SetActorRelativeTransform(Data.Transform);

	State.EditableActorsInPrefab.Add(Data.Guid, Actor.GetPathName());
	Result.Attach(Actor, Data.AttachedTo);
}

void UpdatePermanentPrefabPart(AActor Prefab, FPrefabState& State, FPrefabPointLight Data, FPrefabUpdateResult& Result)
{
	UPointLightComponent Comp = Cast<UPointLightComponent>(GetPermanentPrefabComponent(Prefab, Result, State, Data.Guid));
	if (Comp == nullptr)
		Comp = Editor::AddInstanceComponentInEditor(Prefab, UPointLightComponent, NAME_None);

	Comp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Data.Transform));
	Comp.IsVisualizationComponent = true;
	Comp.bIsEditorOnly = false;

	FPrefabPointLight CurrentData;
	CurrentData.SetFromLight(Comp);

	Editor::UpdateLightComponentEditorSpriteSize(Comp, 0.5 * Data.EditorBillboardScale);

	if (Data.IsChanged(CurrentData))
	{
		Comp.SetMobility(EComponentMobility::Movable);
		Data.Editor_AssignToLight(Comp);
		Comp.SetMobility(EComponentMobility::Static);
	}

	Result.UsedComponent(Data.Guid, Comp);
}

FPrefabProp GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, AHazeProp Actor)
{
	FPrefabProp Prop;
	Prop.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	Prop.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	Prop.PropSettings = Actor.PropSettings;
	Prop.StaticComponentTags = Editor::ReadStaticComponentTags(UHazePropComponent::Get(Actor));

	if (Actor.AttachParentActor != Prefab)
		Prop.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);

	return Prop;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabProp Prop)
{
	AHazeProp PropActor = AHazeProp::Spawn(Level = Prefab.GetLevel());

	if (!Prop.Label.IsEmpty())
		PropActor.SetActorLabel(Prop.Label);
	else
		Editor::SetActorLabelUnique(PropActor, Prop.PropSettings.StaticMesh.Name+" 1");

	PropActor.AttachToActor(Prefab);
	PropActor.SetActorRelativeTransform(Prop.Transform);
	PropActor.OverrideSettings(Prop.PropSettings);

	Editor::WriteStaticComponentTags(UHazePropComponent::Get(PropActor), Prop.StaticComponentTags);

	State.EditableActorsInPrefab.Add(Prop.Guid, PropActor.GetPathName());

	Result.Attach(PropActor, Prop.AttachedTo);
}

void UpdatePermanentPrefabPart(AActor Prefab, FPrefabState& State, FPrefabProp Prop, FPrefabUpdateResult& Result)
{
	UHazePropComponent PropComp = Cast<UHazePropComponent>(GetPermanentPrefabComponent(Prefab, Result, State, Prop.Guid));
	if (PropComp == nullptr)
		PropComp = Editor::AddInstanceComponentInEditor(Prefab, UHazePropComponent, NAME_None);

	PropComp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Prop.Transform));

	FHazePropSettings Settings = Prop.PropSettings;

	if (State.InstanceSettings.LightmapResolutionScale != -1)
	{
		if (Settings.bOverrideLightMapRes)
		{
			Settings.OverriddenLightMapRes = Math::Max(Math::CeilToInt(Settings.OverriddenLightMapRes * State.InstanceSettings.LightmapResolutionScale), 8);
		}
		else if (Settings.StaticMesh != nullptr)
		{
			Settings.bOverrideLightMapRes = true;
			Settings.OverriddenLightMapRes = Math::Max(Math::CeilToInt(Settings.StaticMesh.LightMapResolution * State.InstanceSettings.LightmapResolutionScale), 8);
		}
	}

	PropComp.ConfigureFromConstructionScript(Settings);

	// Bit of a hack, setting it as a visualization component makes it not editable, but still work in game :D
	PropComp.IsVisualizationComponent = true;
	PropComp.bIsEditorOnly = false;
	Editor::WriteStaticComponentTags(PropComp, Prop.StaticComponentTags);

	Result.UsedComponent(Prop.Guid, PropComp);
}

void UpdatePermanentMergedMesh(AActor Prefab, FPrefabState& State, FPrefabData Data, FPrefabUpdateResult& Result)
{
	UHazePropComponent PropComp = Cast<UHazePropComponent>(GetPermanentPrefabComponent(Prefab, Result, State, GUID_MergedMesh));
	if (PropComp == nullptr)
		PropComp = Editor::AddInstanceComponentInEditor(Prefab, UHazePropComponent, NAME_None);

	PropComp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Data.MergedMeshTransform));
	PropComp.ConfigureFromConstructionScript(Data.MergedMeshSettings);

	Result.UsedComponent(GUID_MergedMesh, PropComp);
}

FPrefabChildPrefab GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, APrefabRoot Actor)
{
	FPrefabChildPrefab ChildPrefab;
	ChildPrefab.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	ChildPrefab.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	ChildPrefab.PrefabAsset = Actor.PrefabAsset;

	if (!Actor.GetActorLabel().StartsWith("Prefab "))
		ChildPrefab.Label = Actor.GetActorLabel();

	if (Actor.AttachParentActor != Prefab)
		ChildPrefab.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);

	return ChildPrefab;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabChildPrefab ChildPrefab)
{
	APrefabRoot ChildPrefabActor = APrefabRoot::Spawn(Level = Prefab.GetLevel());
	if (!ChildPrefab.Label.IsEmpty())
		ChildPrefabActor.SetActorLabel(ChildPrefab.Label);
	else
		Editor::SetActorLabelUnique(ChildPrefabActor, "Prefab "+ChildPrefab.PrefabAsset.Name+" 1");

	ChildPrefabActor.AttachToActor(Prefab);
	ChildPrefabActor.SetActorRelativeTransform(ChildPrefab.Transform);
	ChildPrefabActor.PrefabAsset = ChildPrefab.PrefabAsset;

	// TODO: Add recursion checks here
	if (!ChildPrefabActor.PrefabState.bEditable)
		ChildPrefabActor.UpdatePrefabToData();

	State.EditableActorsInPrefab.Add(ChildPrefab.Guid, ChildPrefabActor.GetPathName());

	Result.Attach(ChildPrefabActor, ChildPrefab.AttachedTo);
}

FPrefabNiagaraSystem GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, AHazeNiagaraActor Actor)
{
	FPrefabNiagaraSystem PartData;
	PartData.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	PartData.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	PartData.NiagaraSystem = Actor.NiagaraComponent0.Asset;
	Actor.NiagaraComponent0.GetAllOverriddenPrimitiveParameters(PartData.Variables);

	if (Actor.AttachParentActor != Prefab)
		PartData.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);
	return PartData;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabNiagaraSystem Data)
{
	AHazeNiagaraActor PartActor = AHazeNiagaraActor::Spawn(Level = Prefab.GetLevel());

	PartActor.AttachToActor(Prefab);
	PartActor.SetActorRelativeTransform(Data.Transform);
	PartActor.NiagaraComponent0.SetAsset(Data.NiagaraSystem);
	PartActor.NiagaraComponent0.ApplyPrimitiveParameterOverrides(Data.Variables);

	State.EditableActorsInPrefab.Add(Data.Guid, PartActor.GetPathName());
	Result.Attach(PartActor, Data.AttachedTo);
}

void UpdatePermanentPrefabPart(AActor Prefab, FPrefabState& State, FPrefabNiagaraSystem Data, FPrefabUpdateResult& Result)
{
	UNiagaraComponent PropComp = Cast<UNiagaraComponent>(GetPermanentPrefabComponent(Prefab, Result, State, Data.Guid));
	if (PropComp == nullptr)
		PropComp = Editor::AddInstanceComponentInEditor(Prefab, UNiagaraComponent, NAME_None);

	PropComp.IsVisualizationComponent = true;
	PropComp.bIsEditorOnly = false;
	PropComp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Data.Transform));
	PropComp.SetAsset(Data.NiagaraSystem);
	PropComp.ResetParameterOverrides();
	PropComp.ApplyPrimitiveParameterOverrides(Data.Variables);

	Result.UsedComponent(Data.Guid, PropComp);
}

FPrefabHazeSphere GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, AHazeSphere Actor)
{
	UHazeSphereComponent HazeSphereComp = UHazeSphereComponent::Get(Actor);

	FPrefabHazeSphere PartData;
	PartData.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	PartData.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	PartData.Type = HazeSphereComp.Type;
	PartData.Opacity = HazeSphereComp.Opacity;
	PartData.Softness = HazeSphereComp.Softness;
	PartData.bLinear = HazeSphereComp.bLinear;
	PartData.ColorType = HazeSphereComp.ColorType;
	PartData.ColorA = HazeSphereComp.ColorA;
	PartData.ColorB = HazeSphereComp.ColorB;
	PartData.MinTemperature = HazeSphereComp.MinTemperature;
	PartData.MaxTemperature = HazeSphereComp.MaxTemperature;
	PartData.Contrast = HazeSphereComp.Contrast;
	PartData.Offset = HazeSphereComp.Offset;
	PartData.bApplyFog = HazeSphereComp.ApplyFog;
	PartData.TranslucencyPriority = HazeSphereComp.TranslucencySortPriority;
	PartData.CullingDistanceMultiplier = HazeSphereComp.CullingDistanceMultiplier;
	PartData.EditorBillboardScale = Actor.EditorBillboardScale;
	PartData.bBackgroundOnly = HazeSphereComp.bBackgroundOnly;

	if (Actor.AttachParentActor != Prefab)
		PartData.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);

	return PartData;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabHazeSphere Data)
{
	TSubclassOf<AHazeSphere> HazeSphereClass = Cast<UClass>(LoadObject(nullptr, "/Game/Environment/Blueprints/BP_HazeSphere.BP_HazeSphere_C"));
	AHazeSphere PartActor = SpawnActor(HazeSphereClass, Level = Prefab.GetLevel());

	PartActor.EditorBillboardScale = Data.EditorBillboardScale;
	Editor::UpdateEditorSpriteSize(PartActor, Data.EditorBillboardScale);

	PartActor.AttachToActor(Prefab);
	PartActor.SetActorRelativeTransform(Data.Transform);

	UHazeSphereComponent HazeSphereComp = UHazeSphereComponent::Get(PartActor);
	HazeSphereComp.Type = Data.Type;
	HazeSphereComp.Opacity = Data.Opacity;
	HazeSphereComp.Softness = Data.Softness;
	HazeSphereComp.bLinear = Data.bLinear;
	HazeSphereComp.ColorType = Data.ColorType;
	HazeSphereComp.ColorA = Data.ColorA;
	HazeSphereComp.ColorB = Data.ColorB;
	HazeSphereComp.MinTemperature = Data.MinTemperature;
	HazeSphereComp.MaxTemperature = Data.MaxTemperature;
	HazeSphereComp.Contrast = Data.Contrast;
	HazeSphereComp.Offset = Data.Offset;
	HazeSphereComp.ApplyFog = Data.bApplyFog;
	HazeSphereComp.SetTranslucentSortPriority(Data.TranslucencyPriority);
	HazeSphereComp.CullingDistanceMultiplier = Data.CullingDistanceMultiplier;
	HazeSphereComp.bBackgroundOnly = Data.bBackgroundOnly;

	HazeSphereComp.ConstructionScript_Hack();

	State.EditableActorsInPrefab.Add(Data.Guid, PartActor.GetPathName());
	Result.Attach(PartActor, Data.AttachedTo);
}

void UpdatePermanentPrefabPart(AActor Prefab, FPrefabState& State, FPrefabHazeSphere Data, FPrefabUpdateResult& Result)
{
	UHazeSphereComponent HazeSphereComp = Cast<UHazeSphereComponent>(GetPermanentPrefabComponent(Prefab, Result, State, Data.Guid));
	if (HazeSphereComp == nullptr)
		HazeSphereComp = Editor::AddInstanceComponentInEditor(Prefab, UHazeSphereComponent, NAME_None);

	HazeSphereComp.IsVisualizationComponent = true;
	HazeSphereComp.bIsEditorOnly = false;
	HazeSphereComp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Data.Transform));

	HazeSphereComp.Type = Data.Type;
	HazeSphereComp.Opacity = Data.Opacity;
	HazeSphereComp.Softness = Data.Softness;
	HazeSphereComp.bLinear = Data.bLinear;
	HazeSphereComp.ColorType = Data.ColorType;
	HazeSphereComp.ColorA = Data.ColorA;
	HazeSphereComp.ColorB = Data.ColorB;
	HazeSphereComp.MinTemperature = Data.MinTemperature;
	HazeSphereComp.MaxTemperature = Data.MaxTemperature;
	HazeSphereComp.Contrast = Data.Contrast;
	HazeSphereComp.Offset = Data.Offset;
	HazeSphereComp.ApplyFog = Data.bApplyFog;
	HazeSphereComp.SetTranslucentSortPriority(Data.TranslucencyPriority);
	HazeSphereComp.CullingDistanceMultiplier = Data.CullingDistanceMultiplier;
	HazeSphereComp.bBackgroundOnly = Data.bBackgroundOnly;

	UClass HazeSphereClass = Cast<UClass>(LoadObject(nullptr, "/Game/Environment/Blueprints/BP_HazeSphere.BP_HazeSphere_C"));
	auto HazeSphereCDO = UHazeSphereComponent::Get(Cast<AActor>(HazeSphereClass.DefaultObject));
	HazeSphereComp.HazeSphereMaterial			 			 = HazeSphereCDO.HazeSphereMaterial			 				;
	HazeSphereComp.HazeSphereMaterial_Fog			 		 = HazeSphereCDO.HazeSphereMaterial_Fog			 			;
	HazeSphereComp.HazeSphereMaterial_Distant			 	 = HazeSphereCDO.HazeSphereMaterial_Distant			 		;
	HazeSphereComp.HazeSphereMaterial_Fog_Distant			 = HazeSphereCDO.HazeSphereMaterial_Fog_Distant				;
	HazeSphereComp.HazeSphereMaterial_Advanced			 	 = HazeSphereCDO.HazeSphereMaterial_Advanced			 	;
	HazeSphereComp.HazeSphereMaterial_Advanced_Fog			 = HazeSphereCDO.HazeSphereMaterial_Advanced_Fog			;
	HazeSphereComp.HazeSphereMaterial_Advanced_Distant		 = HazeSphereCDO.HazeSphereMaterial_Advanced_Distant		;
	HazeSphereComp.HazeSphereMaterial_Advanced_Fog_Distant	 = HazeSphereCDO.HazeSphereMaterial_Advanced_Fog_Distant	;

	HazeSphereComp.CubeMesh = HazeSphereCDO.CubeMesh;
	HazeSphereComp.SphereMesh = HazeSphereCDO.SphereMesh;

	HazeSphereComp.ConstructionScript_Hack();

	Result.UsedComponent(Data.Guid, HazeSphereComp);
}

FPrefabPropLine GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, APropLine Actor)
{
	FPrefabPropLine PartData;
	PartData.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	PartData.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	PartData.Preset = Actor.Preset;
	PartData.MergedMeshes = Actor.MergedMeshes;
	PartData.Settings = Actor.Settings;
	PartData.Type = Actor.Type;
	PartData.MeshDistribution = Actor.MeshDistribution;
	PartData.MeshStretching = Actor.MeshStretching;
	PartData.Segments = Actor.Segments;
	PartData.RandomizeTweak = Actor.RandomizeTweak;
	PartData.MaximumMergedMeshSize = Actor.MaximumMergedMeshSize;

	PartData.SplineSettings = Actor.PropSpline.SplineSettings;
	PartData.SplinePoints = Actor.PropSpline.SplinePoints;

	if (Actor.AttachParentActor != Prefab)
		PartData.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);

	TArray<UHazePropComponent> PropComps;
	Actor.GetComponentsByClass(PropComps);

	for (UHazePropComponent Prop : PropComps)
	{
		FPrefabPropLineStaticMeshElement Element;
		Element.ElementName = Prop.Name;
		Element.Transform = Prop.WorldTransform.GetRelativeTransform(Prefab.ActorTransform);
		Element.PropSettings = Prop.Settings;

		PartData.StaticMeshElements.Add(Element);
	}

	PartData.StaticMeshElements.Sort();

	TArray<UHazePropSplineMeshComponent> SplineMeshComps;
	Actor.GetComponentsByClass(SplineMeshComps);

	for (UHazePropSplineMeshComponent Prop : SplineMeshComps)
	{
		FPrefabPropLineSplineMeshElement Element;
		Element.ElementName = Prop.Name;
		Element.Transform = Prop.WorldTransform.GetRelativeTransform(Prefab.ActorTransform);
		Element.PropSettings = Prop.Settings;

		Element.StartScale = Prop.StartScale;
		Element.EndScale = Prop.EndScale;
		Element.StartLocation = Prop.GetStartPosition();
		Element.EndLocation = Prop.GetEndPosition();
		Element.StartTangent = Prop.StartTangent;
		Element.EndTangent = Prop.EndTangent;
		Element.EndRoll = Prop.EndRoll;
		Element.SplineUpDir = Prop.SplineUpDir;
		Element.ForwardAxis = Prop.ForwardAxis;

		PartData.SplineMeshElements.Add(Element);
	}

	PartData.SplineMeshElements.Sort();

	return PartData;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabPropLine Data)
{
	APropLine PartActor = APropLine::Spawn(Level = Prefab.GetLevel());

	PartActor.AttachToActor(Prefab);
	PartActor.SetActorRelativeTransform(Data.Transform);

	PartActor.Preset = Data.Preset;
	PartActor.MergedMeshes = Data.MergedMeshes;
	PartActor.Settings = Data.Settings;
	PartActor.Type = Data.Type;
	PartActor.MeshDistribution = Data.MeshDistribution;
	PartActor.MeshStretching = Data.MeshStretching;
	PartActor.Segments = Data.Segments;
	PartActor.RandomizeTweak = Data.RandomizeTweak;
	PartActor.MaximumMergedMeshSize = Data.MaximumMergedMeshSize;

	PartActor.PropSpline.SplineSettings = Data.SplineSettings;
	PartActor.PropSpline.SplinePoints = Data.SplinePoints;

	State.EditableActorsInPrefab.Add(Data.Guid, PartActor.GetPathName());
	Result.Attach(PartActor, Data.AttachedTo);

	PartActor.PropSpline.UpdateSpline();
	PartActor.RerunConstructionScripts();
}

void UpdatePermanentPrefabPart(AActor Prefab, FPrefabState& State, FPrefabPropLine Data, FPrefabUpdateResult& Result)
{
	for (int i = 0, Count = Data.StaticMeshElements.Num(); i < Count; ++i)
	{
		const FPrefabPropLineStaticMeshElement& Prop = Data.StaticMeshElements[i];
		FGuid ElementGuid = Data.Guid;
		ElementGuid[3] += uint(i);

		UHazePropComponent PropComp = Cast<UHazePropComponent>(GetPermanentPrefabComponent(Prefab, Result, State, ElementGuid));
		if (PropComp == nullptr)
			PropComp = Editor::AddInstanceComponentInEditor(Prefab, UHazePropComponent, NAME_None);

		PropComp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Prop.Transform));
		PropComp.ConfigureFromConstructionScript(Prop.PropSettings);

		PropComp.IsVisualizationComponent = true;
		PropComp.bIsEditorOnly = false;

		Result.UsedComponent(ElementGuid, PropComp);
	}

	for (int i = 0, Count = Data.SplineMeshElements.Num(); i < Count; ++i)
	{
		const FPrefabPropLineSplineMeshElement& Prop = Data.SplineMeshElements[i];
		FGuid ElementGuid = Data.Guid;
		ElementGuid[3] -= uint(i);

		UHazePropSplineMeshComponent PropComp = Cast<UHazePropSplineMeshComponent>(GetPermanentPrefabComponent(Prefab, Result, State, ElementGuid));
		if (PropComp == nullptr)
			PropComp = Editor::AddInstanceComponentInEditor(Prefab, UHazePropSplineMeshComponent, NAME_None);

		PropComp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Prop.Transform));

		PropComp.SetStartScale(Prop.StartScale, false);
		PropComp.SetEndScale(Prop.EndScale, false);
		PropComp.SetStartAndEnd(
			Prop.StartLocation, Prop.StartTangent,
			Prop.EndLocation, Prop.EndTangent,
			false
		);
		PropComp.SetStartRoll(0.0, false);
		PropComp.SetEndRoll(Prop.EndRoll, false);
		PropComp.SetSplineUpDir(Prop.SplineUpDir, false);
		PropComp.SetForwardAxis(Prop.ForwardAxis, false);

		PropComp.ConfigureFromConstructionScript(Prop.PropSettings);

		PropComp.IsVisualizationComponent = true;
		PropComp.bIsEditorOnly = false;

		PropComp.UpdateMesh();
		Result.UsedComponent(ElementGuid, PropComp);
	}
}

FPrefabSpotSoundData GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, APrefabSpotSound Actor)
{
	FPrefabSpotSoundData SpotSound;
	SpotSound.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	SpotSound.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	SpotSound.Asset = Actor.AssetData.GetAsset();
	SpotSound.AttenuationScale = Actor.AttenuationScale;
	SpotSound.DefaultRtpcs = Actor.DefaultRtpcs;
	SpotSound.NodeProperties = Actor.NodeProperties;
	SpotSound.bLinkedToZone = Actor.bLinkedToZone;
	SpotSound.bFollowRelevance = Actor.bFollowRelevance;

	if (Actor.AttachParentActor != Prefab)
		SpotSound.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);
	return SpotSound;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabSpotSoundData Data)
{
	APrefabSpotSound Actor = APrefabSpotSound::Spawn(Level = Prefab.GetLevel());
	Actor.AssetData.SetSoundAssetData(Data.Asset);
	Actor.AttenuationScale = Data.AttenuationScale;
	Actor.DefaultRtpcs = Data.DefaultRtpcs;
	Actor.NodeProperties = Data.NodeProperties;
	Actor.bLinkedToZone = Data.bLinkedToZone;
	Actor.bFollowRelevance = Data.bFollowRelevance;
	Actor.ApplyOnComponent();

	Actor.AttachToActor(Prefab);
	Actor.SetActorRelativeTransform(Data.Transform);

	State.EditableActorsInPrefab.Add(Data.Guid, Actor.GetPathName());
	Result.Attach(Actor, Data.AttachedTo);
}

void UpdatePermanentPrefabPart(AActor Prefab, FPrefabState& State, FPrefabSpotSoundData Data, FPrefabUpdateResult& Result)
{
	USpotSoundComponent Comp = Cast<USpotSoundComponent>(GetPermanentPrefabComponent(Prefab, Result, State, Data.Guid));
	if (Comp == nullptr)
		Comp = Editor::AddInstanceComponentInEditor(Prefab, USpotSoundComponent, NAME_None);

	Comp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Data.Transform));
	Comp.IsVisualizationComponent = true;
	Comp.bIsEditorOnly = false;

	Comp.AssetData.SetSoundAssetData(Data.Asset);
	Comp.Settings.AttenuationScale = Data.AttenuationScale;
	Comp.Settings.DefaultRtpcs = Data.DefaultRtpcs;
	Comp.Settings.NodeProperties = Data.NodeProperties;
	Comp.bLinkToZone = Data.bLinkedToZone;
	Comp.bLinkedZoneFollowRelevance = Data.bFollowRelevance;

	Result.UsedComponent(Data.Guid, Comp);
}

FPrefabDecalData GatherDataFromEditablePrefabPart(APrefabRoot Prefab, FPrefabState& State, ADecalActor Actor)
{
	FPrefabDecalData Data;
	Data.Guid = GetOrCreateGuidForEditableActor(State, Actor);
	Data.Transform = Actor.ActorTransform.GetRelativeTransform(Prefab.ActorTransform);
	Data.Material = Actor.Decal.DecalMaterial;
	Data.DecalColor = Actor.Decal.DecalColor;
	Data.DecalSize = Actor.Decal.DecalSize;

	if (Actor.AttachParentActor != Prefab)
		Data.AttachedTo = GetOrCreateGuidForEditableActor(State, Actor.AttachParentActor);
	return Data;
}

void CreateEditablePrefabPart(AActor Prefab, FPrefabState& State, FPrefabEditResult& Result, FPrefabDecalData Data)
{
	ADecalActor Actor = ADecalActor::Spawn(Level = Prefab.GetLevel());
	Actor.Decal.SetDecalMaterial(Data.Material);
	Actor.Decal.SetDecalColor(Data.DecalColor);
	Actor.Decal.SetDecalSize(Data.DecalSize);

	Actor.AttachToActor(Prefab);
	Actor.SetActorRelativeTransform(Data.Transform);

	State.EditableActorsInPrefab.Add(Data.Guid, Actor.GetPathName());
	Result.Attach(Actor, Data.AttachedTo);
}

void UpdatePermanentPrefabPart(AActor Prefab, FPrefabState& State, FPrefabDecalData Data, FPrefabUpdateResult& Result)
{
	UDecalComponent Comp = Cast<UDecalComponent>(GetPermanentPrefabComponent(Prefab, Result, State, Data.Guid));
	if (Comp == nullptr)
		Comp = Editor::AddInstanceComponentInEditor(Prefab, UDecalComponent, NAME_None);

	Comp.SetRelativeTransform(FTransform::ApplyRelative(Result.OffsetTransform, Data.Transform));
	Comp.IsVisualizationComponent = true;
	Comp.bIsEditorOnly = false;
	Comp.SetDecalMaterial(Data.Material);
	Comp.SetDecalColor(Data.DecalColor);
	Comp.SetDecalSize(Data.DecalSize);

	Result.UsedComponent(Data.Guid, Comp);
}

}
#endif