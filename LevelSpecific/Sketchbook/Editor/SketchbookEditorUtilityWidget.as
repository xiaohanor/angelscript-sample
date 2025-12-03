enum ESketchbookSentenceLayer
{
	Default,

	Layer1,
	Layer2,
	Layer3,

	BossDemon,
	BossCrab,
	BossDuck,

	MAX,
};

UCLASS(Abstract)
class USketchbookEditorUtilityWidget : UEditorUtilityWidget
{
	default TabDisplayName = FText::FromString("Sketchbook Tools");

	UPROPERTY(BindWidget)
	UHazeImmediateWidget ImmediateWidget;

	bool bShowSketchbookShader = true;
	bool bDrawInViewport = true;

	bool bPreviewCamera = false;
	bool bWasPreviewingCamera = false;
	float PreviewCameraFOV = 5;
	float PreviewCameraDistance = 15000.0;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Sketchbook::Editor::RefreshSentenceLayers();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UHazeImmediateDrawer Drawer = ImmediateWidget.GetDrawer();
		if (Drawer == nullptr || !Drawer.IsVisible())
			return;

		FHazeImmediateVerticalBoxHandle VerticalBox = Drawer.BeginVerticalBox();

		if(!Sketchbook::Editor::IsInSketchbookLevel())
		{
			auto SettingsSection = VerticalBox.Section("Whoopsie!");
			SettingsSection.Text("This window cannot be used in this level c:");
			return;
		}

		DrawSettings(VerticalBox);

		DrawConvertToDrawableProp(VerticalBox);

		DrawAddDrawableObjectComponent(VerticalBox);

		DrawCreateDrawablePropGroup(VerticalBox);

		DrawSentences(VerticalBox);

		// if(VerticalBox.Button("Fix Everything").WasClicked())
		// {
		// 	FTransform FixTransform = FTransform(FQuat(FVector::UpVector, PI));
		// 	auto AllActors = Editor::GetAllEditorWorldActorsOfClass(AActor);
		// 	for(auto Actor : AllActors)
		// 	{
		// 		if(Actor.AttachParentActor != nullptr)
		// 			continue;

		// 		Actor.SetActorTransform(Actor.ActorTransform * FixTransform);
		// 	}
		// }
	}

	void DrawSettings(FHazeImmediateVerticalBoxHandle VerticalBox)
	{
		FHazeImmediateSectionHandle SettingsSection = VerticalBox.Section("Settings");

		{
			bool bPreviousValue = bShowSketchbookShader;
			bShowSketchbookShader = SettingsSection.CheckBox()
				.Label("Show Sketchbook Shader")
				.Checked(bShowSketchbookShader)
			;

			if(bShowSketchbookShader != bPreviousValue)
				RefreshShowSketchbookOutline();
		}

		bDrawInViewport = SettingsSection.CheckBox()
			.Label("Draw selection in Viewport")
			.Checked(bDrawInViewport)
		;

		bool bShouldRefreshOutlines = false;

		auto EditorSubsystem = USketchbookEditorSubsystem::Get();

		{
			bool bPreviousValue = EditorSubsystem.bShowDrawOutlines;
			EditorSubsystem.bShowDrawOutlines = SettingsSection.CheckBox()
				.Label("Show DrawnFromStart Outlines")
				.Checked(EditorSubsystem.bShowDrawOutlines)
			;
			if(bPreviousValue != EditorSubsystem.bShowDrawOutlines)
				bShouldRefreshOutlines = true;
		}

		if(EditorSubsystem.bShowDrawOutlines)
		{
			float PreviousValue = EditorSubsystem.DrawOutlinesThickness;
			EditorSubsystem.DrawOutlinesThickness = SettingsSection.FloatInput()
				.Label("DrawnFromStart Outline Thickness")
				.MinMax(1, 50)
				.Value(EditorSubsystem.DrawOutlinesThickness)
				.Tooltip("Default is 2")
			;

			if(!Math::IsNearlyEqual(PreviousValue, EditorSubsystem.DrawOutlinesThickness))
				bShouldRefreshOutlines = true;
		}

		if(bShouldRefreshOutlines)
			RefreshOutlines();

		DrawPreviewCamera(SettingsSection);

		if(SettingsSection.Button("Force update all drawables").WasClicked())
			Sketchbook::Editor::ForceUpdateAllDrawables();

		if(SettingsSection.Button(f"Calculate Statistics").WasClicked())
		{
			ASketchbookSentence LongestSentence = nullptr;
			float LongestSentenceDuration = -1;
			float TotalSentencesDuration = 0;

			FSketchbookWord LongestWord;
			float LongestWordDuration = -1;
			float TotalWordsDuration = 0;
			int WordCount = 0;

			TArray<ASketchbookSentence> SentenceActors = ::Editor::GetAllEditorWorldActorsOfClass(ASketchbookSentence);
			for(auto Sentence : SentenceActors)
			{
				const float SentenceDuration = Sentence.DrawableSentenceComp.GetSentenceDrawDuration(false);
				TotalSentencesDuration += SentenceDuration;
				if(SentenceDuration > LongestSentenceDuration)
				{
					LongestSentence = Sentence;
					LongestSentenceDuration = SentenceDuration;
				}

				for(FSketchbookWord Word : Sentence.DrawableSentenceComp.Words)
				{
					const float WordDuration = Word.GetDrawDuration(Sentence.DrawableSentenceComp, false);
					TotalWordsDuration += WordDuration;
					WordCount++;

					if(WordDuration > LongestWordDuration)
					{
						LongestWordDuration = WordDuration;
						LongestWord = Word;
					}
				}
			}

			const float AverageSentenceDuration = TotalSentencesDuration / SentenceActors.Num();
			const float AverageWordDuration = TotalWordsDuration / WordCount;

			Editor::MessageDialog(EAppMsgType::Ok, FText::FromString(
				f"Longest Duration Sentence: {LongestSentence.TextRenderer.Text.ToString()}." +
				f"\nLongest Sentence Duration: {LongestSentenceDuration} seconds." +
				f"\nAverage Sentence Duration: {AverageSentenceDuration} seconds." +
				"\n" +
				f"\nWord Count: {WordCount} words." +
				f"\nLongest Duration Word: {LongestWord.Word}." +
				f"\nLongest Word Duration: {LongestWordDuration} seconds." +
				f"\nAverage Word Duration: {AverageWordDuration} seconds."
			));
		}
	}

	void DrawPreviewCamera(FHazeImmediateSectionHandle SettingsSection)
	{
		bPreviewCamera = SettingsSection.CheckBox()
			.Label("Preview Camera")
			.Checked(bPreviewCamera)
		;

		if(bPreviewCamera)
		{
			if(!bWasPreviewingCamera)
			{
				bWasPreviewingCamera = true;
			}

			PreviewCameraFOV = SettingsSection.FloatInput()
				.MinMax(1, 90)
				.Value(PreviewCameraFOV)
				.Label("Preview FOV")
				.Tooltip("Default is 5")
			;

			PreviewCameraDistance = SettingsSection.FloatInput()
				.MinMax(8000, 40000)
				.Value(PreviewCameraDistance)
				.Label("Preview Distance")
				.Tooltip("Default is 15,000")
			;

			Editor::SetEditorViewFOV(PreviewCameraFOV);

			FVector ViewLocation = Editor::GetEditorViewLocation();
			ViewLocation.X = -PreviewCameraDistance;
			Editor::SetEditorViewLocation(ViewLocation);

			Editor::SetEditorViewRotation(FRotator::MakeFromXZ(FVector::ForwardVector, FVector::UpVector));
		}
		else
		{
			if(bWasPreviewingCamera)
			{
				FVector ViewLocation = Editor::GetEditorViewLocation();
				ViewLocation.X = -1000;
				Editor::SetEditorViewLocation(ViewLocation);

				bWasPreviewingCamera = false;
				Editor::SetEditorViewFOV(90);
			}
		}
	}

	void RefreshShowSketchbookOutline()
	{
		TArray<APostProcessVolume> PostProcessVolumes = Editor::GetAllEditorWorldActorsOfClass(APostProcessVolume);
		for(auto Actor : PostProcessVolumes)
		{
			auto PostProcessVolume = Cast<APostProcessVolume>(Actor);
			if(PostProcessVolume == nullptr)
				continue;

			PostProcessVolume.BlendWeight = bShowSketchbookShader ? 1 : 0;
		}
	}

	void RefreshOutlines()
	{
		TArray<AActor> Actors = Editor::GetAllEditorWorldActorsOfClass(AActor);

		for(auto Actor : Actors)
		{
			auto DrawableEditorRenderedComp = USketchbookDrawableEditorRenderedComponent::Get(Actor);
			if(DrawableEditorRenderedComp == nullptr)
				continue;

			DrawableEditorRenderedComp.MarkRenderStateDirty();
		}
	}

	void DrawConvertToDrawableProp(FHazeImmediateVerticalBoxHandle VerticalBox)
	{
		TArray<AActor> ActorsToConvert;

		for(auto SelectedActor : Editor::SelectedActors)
		{
			if(!Sketchbook::Editor::CanConvertActorToDrawableProp(SelectedActor))
				continue;

			if(bDrawInViewport)
			{
				FVector Origin;
				FVector Extents;
				SelectedActor.GetActorBounds(false, Origin, Extents);
				Debug::DrawDebugBox(Origin, Extents, FRotator::ZeroRotator, Sketchbook::Editor::ConvertColor, Sketchbook::Editor::BoundsThickness);

				//Debug::DrawDebugString(Origin, "Can Convert", Sketchbook::ConvertColor, Scale = 1.5);
			}

			ActorsToConvert.Add(SelectedActor);
		}

		if(ActorsToConvert.IsEmpty())
			return;

		auto ConvertSection = VerticalBox
			.Section("Convert to Drawable Prop")
			.TitleColor(FLinearColor::Black)
			.Color(Sketchbook::Editor::ConvertColor)
		;
			
		ConvertSection
			.Text(f"Can convert {ActorsToConvert.Num()} selected actor(s) to drawable prop(s).")
			.Color(FLinearColor::Black);

		if(ConvertSection.Button("Convert All").WasClicked())
			ConvertAllToDrawablePropActors(ActorsToConvert);

		// ConvertSection.Spacer(10);

		// for(auto ActorToConvert : ActorsToConvert)
		// {
		// 	if(ConvertSection.Button(f"Convert {ActorToConvert.ActorLabel}").WasClicked())
		// 		ConvertSingleToDrawablePropActor(ActorToConvert);
		// }
	}

	void DrawAddDrawableObjectComponent(FHazeImmediateVerticalBoxHandle VerticalBox)
	{
		TArray<AActor> ActorsToAddDrawableTo;

		for(auto SelectedActor : Editor::SelectedActors)
		{
			if(!Sketchbook::Editor::CanAddDrawableObjectComponentToActor(SelectedActor))
				continue;

			if(bDrawInViewport)
			{
				FVector Origin;
				FVector Extents;
				SelectedActor.GetActorBounds(false, Origin, Extents);
				Debug::DrawDebugBox(Origin, Extents, FRotator::ZeroRotator, Sketchbook::Editor::AddDrawableObjectComponentColor, Sketchbook::Editor::BoundsThickness);

				//Debug::DrawDebugString(Origin, "Can Add DrawableObject", Sketchbook::AddDrawableObjectComponentColor, Scale = 1.5);
			}

			ActorsToAddDrawableTo.Add(SelectedActor);
		}

		if(ActorsToAddDrawableTo.IsEmpty())
			return;

		auto AddDrawableSection = VerticalBox
			.Section("Add DrawableObject Actor")
			.TitleColor(FLinearColor::Black)
			.Color(Sketchbook::Editor::AddDrawableObjectComponentColor)
		;
			
		AddDrawableSection
			.Text(f"Can add DrawableObject to {ActorsToAddDrawableTo.Num()} selected actor(s).")
			.Color(FLinearColor::Black)
		;

		if(AddDrawableSection.Button("Add DrawableObject to All").WasClicked())
		{
			for(auto ActorToAddDrawableTo : ActorsToAddDrawableTo)
			{
				Editor::AddInstanceComponentInEditor(ActorToAddDrawableTo, USketchbookDrawableObjectComponent, NAME_None);

				TArray<UPrimitiveComponent> Primitives;
				ActorToAddDrawableTo.GetComponentsByClass(Primitives);
				for(auto Primitive : Primitives)
				{
					// Never cull
					Primitive.SetCullDistance(BIG_NUMBER);
				}
			}
		}

		// AddDrawableSection.Spacer(10);

		// for(auto ActorToAddDrawableTo : ActorsToAddDrawableTo)
		// {
		// 	if(AddDrawableSection.Button(f"Add Drawable to {ActorToAddDrawableTo.ActorLabel}").WasClicked())
		// 	{
		// 		auto NewComponent = Editor::AddInstanceComponentInEditor(ActorToAddDrawableTo, USketchbookPenDrawableObjectComponent, NAME_None);

		// 			Editor::SelectComponent(NewComponent);
		// 	}
		// }
	}

	void DrawCreateDrawablePropGroup(FHazeImmediateVerticalBoxHandle VerticalBox)
	{
		TArray<ASketchbookDrawableProp> SelectedProps;

		for(auto SelectedActor : Editor::SelectedActors)
		{
			auto Prop = Cast<ASketchbookDrawableProp>(SelectedActor);
			if(Prop == nullptr)
				continue;
			SelectedProps.Add(Prop);
		}

		if(SelectedProps.IsEmpty())
			return;

		const TArray<ASketchbookDrawablePropGroup> PropGroups = Sketchbook::Editor::GetSketchbookPropGroups();

		auto PropGroupSection = VerticalBox
			.Section("Prop Group")
			.TitleColor(FLinearColor::Black)
			.Color(Sketchbook::Editor::PropGroupColor)
		;

		TArray<ASketchbookDrawableProp> PropsToGroup;

		for(int i = SelectedProps.Num() - 1; i >= 0; i--)
		{
			auto Prop = SelectedProps[i];
			ASketchbookDrawablePropGroup Group = Sketchbook::Editor::FindGroupForProp(PropGroups, Prop);

			if(Group != nullptr)
			{
				PropGroupSection
					.Text(f"Selected prop {SelectedProps[i].ActorNameOrLabel} is part of group {Group.ActorNameOrLabel}")
					.Color(FLinearColor::Black);

				if(PropGroupSection.Button("Select Group").WasClicked())
					Editor::SelectActor(Group);

				if(bDrawInViewport)
				{
					FVector Origin, Extents;
					Group.DrawableComp.GetWorldBounds(Origin, Extents);
					Debug::DrawDebugBox(Origin, Extents, FRotator::ZeroRotator, Sketchbook::Editor::PropGroupColor, 10);

					for(auto PropInGroup : Group.DrawableComp.Props)
					{
						PropInGroup.DrawableComp.GetWorldBounds(false, Origin, Extents);
						Debug::DrawDebugBox(Origin, Extents, FRotator::ZeroRotator, Sketchbook::Editor::PropGroupColor, Sketchbook::Editor::BoundsThickness);
						Debug::DrawDebugArrow(Origin, Group.ActorLocation, 1000, Sketchbook::Editor::PropGroupColor, 10, 0, true);
					}
				}
			}
			else
			{
				PropsToGroup.Add(Prop);

				if(bDrawInViewport)
				{
					FVector Origin;
					FVector Extents;
					Prop.GetActorBounds(false, Origin, Extents);
					Debug::DrawDebugBox(Origin, Extents, FRotator::ZeroRotator, Sketchbook::Editor::PropGroupColor, Sketchbook::Editor::BoundsThickness);
				}
			}
		}

		if(PropsToGroup.IsEmpty())
			return;

		if(PropsToGroup.Num() == 1)
		{
			PropGroupSection
			.Text(f"Select more props to create a prop group.")
			.Color(FLinearColor::Black);

			return;
		}

		PropGroupSection
			.Text(f"Can create prop group of {PropsToGroup.Num()} drawable prop(s).")
			.Color(FLinearColor::Black);

		if(PropGroupSection.Button("Create Prop Group").WasClicked())
			CreateDrawablePropGroup(PropsToGroup);
	}

	void ConvertAllToDrawablePropActors(TArray<AActor>& ActorsToConvert) const
	{
		if(ActorsToConvert.IsEmpty())
			return;

		Editor::BeginTransaction("ConvertAllToDrawablePropActors");

		TArray<ASketchbookDrawableProp> DrawableProps;
		for(auto Actor : ActorsToConvert)
		{
			if(Actor == nullptr)
				continue;

			Actor.Modify();

			ASketchbookDrawableProp DrawableProp = Sketchbook::Editor::ReplaceActorWithDrawableProp(Actor);
			if(DrawableProp == nullptr)
				continue;

			DrawableProps.Add(DrawableProp);
		}

		Editor::EndTransaction();

		if(DrawableProps.IsEmpty())
			return;

		if(DrawableProps.Num() > 1)
			Editor::SelectActors(DrawableProps);
		else
			Editor::SelectComponent(DrawableProps[0].DrawableComp);
	}

	void ConvertSingleToDrawablePropActor(AActor ActorToConvert) const
	{
		if(ActorToConvert == nullptr)
			return;

		Editor::BeginTransaction("ConvertSingleToDrawablePropActor");
		ActorToConvert.Modify();

		ASketchbookDrawableProp DrawableProp = Sketchbook::Editor::ReplaceActorWithDrawableProp(ActorToConvert);

		Editor::EndTransaction();

		if(DrawableProp == nullptr)
			return;

		Editor::SelectComponent(DrawableProp.DrawableComp);
	}

	void CreateDrawablePropGroup(TArray<ASketchbookDrawableProp> PropsToGroup)
	{
		if(PropsToGroup.IsEmpty())
			return;

		FVector AverageLocation = FVector::ZeroVector;
		for(auto Prop : PropsToGroup)
			AverageLocation += Prop.ActorLocation;

		AverageLocation /= PropsToGroup.Num();

		AverageLocation.X = 0;

		auto PropGroup = SpawnActor(ASketchbookDrawablePropGroup, AverageLocation);
		PropGroup.DrawableComp.Props = PropsToGroup;

		PropGroup.DrawableComp.SketchbookMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Script/Engine.Material'/Game/LevelSpecific/Sketchbook/Shaders/Reveal/M_SketchBook_MeshReveal.M_SketchBook_MeshReveal'"));
		check(PropGroup.DrawableComp.SketchbookMaterial != nullptr, "Failed to load M_SketchBook_MeshReveal. Has it been moved?");

		PropGroup.DrawableComp.UpdateInEditor(true);

		Editor::SelectActor(PropGroup);
	}

	void DrawSentences(FHazeImmediateVerticalBoxHandle VerticalBox)
	{
		auto Subsystem = USketchbookEditorSubsystem::Get();
		if(Subsystem == nullptr)
			return;

		auto Section = VerticalBox.Section("Sentences");

		bool bNeedsRefresh = false;

		bool bPreviousValue = Subsystem.bShowAllSentenceLayers;
		Subsystem.bShowAllSentenceLayers = Section.CheckBox().Label("Show All Layers").Checked(Subsystem.bShowAllSentenceLayers);
		if(bPreviousValue != Subsystem.bShowAllSentenceLayers)
			bNeedsRefresh = true;

		if(Subsystem.bShowAllSentenceLayers)
		{
			// for(int i = 0; i < int(ESketchbookSentenceLayer::MAX); i++)
			// {
			// 	if(!Subsystem.SentenceLayerMap.Contains(i))
			// 		continue;

			// 	Subsystem.SentenceLayerMap[i] = true;
			// }
		}
		else
		{
			Section.Spacer(6);

			for(int i = 0; i < int(ESketchbookSentenceLayer::MAX); i++)
			{
				ESketchbookSentenceLayer Layer = ESketchbookSentenceLayer(i);
				bool bValue = Subsystem.SentenceLayerMap.FindOrAdd(i, true);

				bPreviousValue = bValue;

				FString OptionString = f"{Layer:n}";
				bValue = Section.CheckBox().Label(OptionString).Checked(bValue);

				Subsystem.SentenceLayerMap[i] = bValue;

				if(bPreviousValue != bValue)
					bNeedsRefresh = true;
			}
		}

		if(bNeedsRefresh)
			Sketchbook::Editor::RefreshSentenceLayers();
	}
};

class USketchbookToolbarExtension : UScriptEditorMenuExtension
{
	default ExtensionPoint = n"LevelEditor.LevelEditorToolBar.User";

	UFUNCTION(BlueprintOverride)
	bool ShouldExtend() const
	{
		return Sketchbook::Editor::IsInSketchbookLevel();
	}

	UFUNCTION(CallInEditor, DisplayName = "Open Sketchbook Tools", Meta = (EditorIcon = "Icons.Details", EditorButtonStyle = "CalloutToolbar"))
	void OpenSketchbookTools()
	{
		Sketchbook::Editor::OpenToolsWindow();
	}
};

namespace Sketchbook::Editor
{
	const FLinearColor ConvertColor = FLinearColor(1.0, 0.407, 0.250); //ColorDebug::Pumpkin;
	const FLinearColor AddDrawableObjectComponentColor = FLinearColor(0.341, 0.058, 0.752); //ColorDebug::Grape;
	const FLinearColor PropGroupColor = FLinearColor(0.317, 0.407, 0.298); //ColorDebug::Camo;
	const float BoundsThickness = 10;

	bool IsInSketchbookLevel()
	{
		return USketchbookEditorSubsystem::Get().IsInSketchbookLevel();
	}

	void ForceUpdateAllDrawables()
	{
		auto AllActors = ::Editor::GetAllEditorWorldActorsOfClass(AActor);
		for(auto Actor : AllActors)
		{
			auto Drawable = USketchbookDrawableComponent::Get(Actor);
			if(Drawable == nullptr)
				continue;

			Drawable.UpdateInEditor(true);
		}
	}

	bool CanConvertActorToDrawableProp(const AActor Actor)
	{
		if(Actor.IsA(ASketchbookDrawableProp))
			return false;

		if(Actor.IsA(AHazeProp))
			return true;

		if(Actor.IsA(AStaticMeshActor))
			return true;

		return false;
	}

	/**
	 * When replacing Actor, return what we need to copy and place on the newly created DrawableProp
	 */
	bool GetPropertiesToCopyForDrawableProp(
		AActor Actor,
		UStaticMesh&out OutStaticMesh,
		FTransform&out OutMeshComponentWorldTransform,
		bool&out bRenderCustomDepthPass,
		int&out CustomDepthStencilValue
	)
	{
		check(Sketchbook::Editor::CanConvertActorToDrawableProp(Actor));

		OutStaticMesh = nullptr;
		OutMeshComponentWorldTransform = FTransform::Identity;

		if(Actor == nullptr)
			return false;

		auto HazeProp = Cast<AHazeProp>(Actor);
		if(HazeProp != nullptr)
		{
			OutStaticMesh = HazeProp.PropSettings.StaticMesh;
			auto PropComponent = UHazePropComponent::Get(HazeProp);
			if(PropComponent == nullptr)
				return false;

			OutMeshComponentWorldTransform = PropComponent.WorldTransform;
			bRenderCustomDepthPass = PropComponent.bRenderCustomDepth;
			CustomDepthStencilValue = PropComponent.CustomDepthStencilValue;
			return true;
		}

		auto StaticMeshActor = Cast<AStaticMeshActor>(Actor);
		if(StaticMeshActor != nullptr)
		{
			OutStaticMesh = StaticMeshActor.StaticMeshComponent.StaticMesh;
			OutMeshComponentWorldTransform = StaticMeshActor.StaticMeshComponent.WorldTransform;
			bRenderCustomDepthPass = StaticMeshActor.StaticMeshComponent.bRenderCustomDepth;
			CustomDepthStencilValue = StaticMeshActor.StaticMeshComponent.CustomDepthStencilValue;
			return true;
		}

		return false;
	}

	/**
	 * Copy the Actor transform, StaticMesh and MeshComponent transform to a new ASketchbookDrawableProp actor
	 * NOTE: This function will destroy OldActor!
	 */
	ASketchbookDrawableProp ReplaceActorWithDrawableProp(AActor OldActor)
	{
		if(!ensure(Sketchbook::Editor::CanConvertActorToDrawableProp(OldActor)))
			return nullptr;

		UStaticMesh StaticMesh;
		FTransform MeshComponentWorldTransform;
		bool bRenderCustomDepthPass;
		int CustomDepthStencilValue;
		if(!Sketchbook::Editor::GetPropertiesToCopyForDrawableProp(OldActor, StaticMesh, MeshComponentWorldTransform, bRenderCustomDepthPass, CustomDepthStencilValue))
			return nullptr;

		if(OldActor == nullptr || StaticMesh == nullptr)
			return nullptr;

		auto DrawableProp = SpawnActor(ASketchbookDrawableProp, bDeferredSpawn = true);

		if(DrawableProp == nullptr)
			return nullptr;

		DrawableProp.RootComponent.SetMobility(OldActor.RootComponent.Mobility);
		DrawableProp.MeshComp.SetMobility(DrawableProp.RootComponent.Mobility);
		
		DrawableProp.MeshComp.SetStaticMesh(StaticMesh);
		DrawableProp.MeshComp.SetRenderCustomDepth(bRenderCustomDepthPass);
		DrawableProp.MeshComp.SetCustomDepthStencilValue(CustomDepthStencilValue);
		FinishSpawningActor(DrawableProp, OldActor.ActorTransform);

		DrawableProp.MeshComp.SetWorldTransform(MeshComponentWorldTransform);

		if(OldActor.AttachParentActor != nullptr)
		{
			DrawableProp.AttachToActor(OldActor.AttachParentActor, OldActor.AttachParentSocketName, EAttachmentRule::KeepWorld);
		}

		DrawableProp.DrawableComp.UpdateInEditor(true);

		DrawableProp.SetActorLabel(OldActor.ActorNameOrLabel);

		::Editor::ReplaceAllActorReferences(OldActor, DrawableProp);
		OldActor.DestroyActor();

		return DrawableProp;
	}

	bool CanAddDrawableObjectComponentToActor(AActor Actor)
	{
		auto Drawable = USketchbookDrawableComponent::Get(Actor);
		if(Drawable != nullptr)
			return false;

		// The actor should be converted instead!
		if(Sketchbook::Editor::CanConvertActorToDrawableProp(Actor))
			return false;

		const auto StaticMesh = UStaticMeshComponent::Get(Actor);
		if(StaticMesh == nullptr)
			return false;

		return true;
	}

	TArray<ASketchbookDrawablePropGroup> GetSketchbookPropGroups()
	{
		TArray<AActor> GroupActors = ::Editor::GetAllEditorWorldActorsOfClass(ASketchbookDrawablePropGroup);
		
		TArray<ASketchbookDrawablePropGroup> PropGroups;
		PropGroups.Reserve(GroupActors.Num());
		for(auto GroupActor : GroupActors)
			PropGroups.Add(Cast<ASketchbookDrawablePropGroup>(GroupActor));
		return PropGroups;
	}

	ASketchbookDrawablePropGroup FindGroupForProp(ASketchbookDrawableProp Prop)
	{
		auto Groups = GetSketchbookPropGroups();
		return FindGroupForProp(Groups, Prop);
	}

	ASketchbookDrawablePropGroup FindGroupForProp(TArray<ASketchbookDrawablePropGroup> Groups, ASketchbookDrawableProp Prop)
	{
		if(!ensure(Prop != nullptr))
			return nullptr;

		for(auto Group : Groups)
		{
			if(Group == nullptr)
				continue;

			if(Group.DrawableComp.Props.Contains(Prop))
				return Group;
		}

		return nullptr;
	}
};