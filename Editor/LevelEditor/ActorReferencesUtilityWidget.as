
struct FActorReferencesList
{
	TWeakObjectPtr<AActor> Actor;
	TArray<TWeakObjectPtr<AActor>> Referencers;
	bool bReferencedByLevelScript = false;
}

class UActorReferencesUtilityWidget : UEditorUtilityWidget
{
	bool bFollowSelection = false;
	bool bVisualizeReferences = false;
	bool bRequestUpdateSelection = false;

	UPROPERTY(BindWidget)
	UHazeImmediateWidget ImmediateWidget;

	TArray<FActorReferencesList> References;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto Drawer = ImmediateWidget.GetDrawer();
		if (!Drawer.IsVisible())
			return;

		auto Root = Drawer.BeginVerticalBox();

		auto ButtonBox = Root
			.SlotPadding(0)
			.BorderBox()
			.BackgroundColor(FLinearColor(0.1, 0.1, 0.1))
			.HorizontalBox();

		ButtonBox
			.SlotFill()
			.Text("Actor References")
			.Bold()
			.Scale(1.4)
		;

		if (ButtonBox.Button("Refresh"))
			UpdateReferencers();

		auto VisualizeCheckBox = ButtonBox
			.SlotPadding(12, 4)
			.CheckBox()
				.Label("Visualize References")
				.Tooltip("Draw lines from the selected actors to their referencers")
				.Checked(bVisualizeReferences)
			;

		bVisualizeReferences = VisualizeCheckBox;

		auto FollowCheckBox = ButtonBox
			.SlotPadding(12, 4)
			.CheckBox()
				.Label("Follow Selection")
				.Tooltip("Keep the same objects showing as were selected when the window was opened. Otherwise, always ")
				.Checked(bFollowSelection)
			;

		bFollowSelection = FollowCheckBox;
		Root.Spacer(10);

		UpdateSelection();

		auto ScrollBox = Root
			.SlotFill()
			.ScrollBox();

		for (const FActorReferencesList& List : References)
		{
			if (List.Referencers.Num() != 0 || List.bReferencedByLevelScript)
			{
				DrawReferencers(ScrollBox, List);
				if (bVisualizeReferences)
					VisualizeReferencers(List);
			}
		}

		for (const FActorReferencesList& List : References)
		{
			if (List.Referencers.Num() == 0 && !List.bReferencedByLevelScript)
			{
				DrawReferencers(ScrollBox, List);
				if (bVisualizeReferences)
					VisualizeReferencers(List);
			}
		}
	}

	void DrawReferencers(FHazeImmediateScrollBoxHandle Root, FActorReferencesList List)
	{
		AActor Actor = List.Actor.Get();
		if (Actor == nullptr)
			return;

		auto Element = Root.Section()
			.SlotHAlign(EHorizontalAlignment::HAlign_Fill)
			.VerticalBox()
		;

		auto HeadBox = Element.HorizontalBox();

		HeadBox
			.SlotFill()
			.Text(Actor.GetActorLabel())
			.Scale(1.5)
			.Color(FLinearColor::LucBlue)
		;

		FString ReferencersText;
		if (List.Referencers.Num() == 0 && !List.bReferencedByLevelScript)
		{
			ReferencersText = "No referencers found...";
		}
		else if (List.bReferencedByLevelScript && List.Referencers.Num() != 0)
		{
			ReferencersText = f"Referenced by {List.Referencers.Num()} Actor(s) and the level blueprint:";
		}
		else if (List.bReferencedByLevelScript)
		{
			ReferencersText = f"Referenced by the level blueprint:";
		}
		else
		{
			ReferencersText = f"Referenced by {List.Referencers.Num()} Actor(s):";
		}

		Element
			.SlotPadding(5, 2)
			.Text(ReferencersText)
			.Color(FLinearColor(0.3, 0.3, 0.3))
		;

		Element.Spacer(5);

		if (List.bReferencedByLevelScript)
		{
			auto HorizBox = Element
				.BorderBox()
				.SlotPadding(1)
				.BackgroundColor(FLinearColor(0.05, 0.05, 0.05))
				.BorderBox()
				.SlotPadding(8, 4)
				.BackgroundColor(FLinearColor(0.02, 0.02, 0.02))
				.HorizontalBox();

			HorizBox
				.SlotVAlign(EVerticalAlignment::VAlign_Center)
				.Text(f"{Actor.Level.Outer.Name}")
				.Scale(1.1)
				.Color(FLinearColor(0.5, 1.0, 0.5))
				;

			HorizBox
				.SlotVAlign(EVerticalAlignment::VAlign_Center)
				.SlotFill()
				.Text(f"(Level Blueprint)")
				.Scale(1.1)
				.Color(FLinearColor(0.3, 0.3, 0.3))
				;

			if (HorizBox.Button("🔍 Open"))
			{
				Blutility::OpenLevelBlueprintToActorReferences(Actor);
			}
		}

		if (List.Referencers.Num() != 0)
		{
			for (TWeakObjectPtr<AActor> Ref : List.Referencers)
			{
				AActor RefActor = Ref.Get();
				if (RefActor == nullptr)
					continue;

				auto HorizBox = Element
					.BorderBox()
					.SlotPadding(1)
					.BackgroundColor(FLinearColor(0.05, 0.05, 0.05))
					.BorderBox()
					.SlotPadding(8, 4)
					.BackgroundColor(FLinearColor(0.02, 0.02, 0.02))
					.HorizontalBox();

				HorizBox
					.SlotVAlign(EVerticalAlignment::VAlign_Center)
					.SlotFill()
					.Text(RefActor.GetActorLabel())
					;

				if (HorizBox
					.Button("🔗 Select")
					.Tooltip("Select this actor"))
				{
					Editor::SelectActor(RefActor, false);
				}

				if (HorizBox
					.Button("🔍 Show")
					.Tooltip("Show this actor in the editor viewport"))
				{
					Editor::SelectActor(RefActor, true);
				}
			}
		}

		Element.Spacer(10);
	}

	void VisualizeReferencers(FActorReferencesList List)
	{
		AActor Actor = List.Actor.Get();
		if (Actor == nullptr)
			return;

		FVector StartLocation = Actor.ActorLocation;

		uint8 Hue = uint8(Actor.Name.Hash % 255);
		FLinearColor Color = FLinearColor::MakeFromHSV8(Hue, 128, 255);

		if (List.bReferencedByLevelScript)
		{
			FVector AboveLocation = StartLocation + FVector(0, 0, 200);
			Debug::DrawDebugString(
				AboveLocation, "Referenced by Level Blueprint",
				Color, 0, 1, ScreenSpaceOffset = FVector2D(0, -20));

			Debug::DrawDebugArrow(
				AboveLocation,
				Math::Lerp(AboveLocation, StartLocation, 0.5),
				200,
				Color,
				10, 0, true
			);

			Debug::DrawDebugLine(
				Math::Lerp(AboveLocation, StartLocation, 0.5),
				StartLocation,
				Color,
				10, 0, true
			);
		}

		if (List.Referencers.Num() != 0)
		{
			for (TWeakObjectPtr<AActor> Ref : List.Referencers)
			{
				AActor RefActor = Ref.Get();
				if (RefActor == nullptr)
					continue;

				FVector RefLocation = RefActor.ActorLocation;

				if (RefActor.IsA(AVolume))
				{
					// Volumes should show the line to the closest edge of their bounds so it's more obvious
					FBox Bounds = RefActor.GetActorLocalBoundingBox(true);

					TArray<FVector> Edges;
					Edges.Add(FVector(0, 0, 0)); Edges.Add(FVector(0, 1, 0));
					Edges.Add(FVector(0, 0, 0)); Edges.Add(FVector(1, 0, 0));
					Edges.Add(FVector(1, 0, 0)); Edges.Add(FVector(1, 1, 0));
					Edges.Add(FVector(0, 1, 0)); Edges.Add(FVector(1, 1, 0));

					Edges.Add(FVector(0, 0, 1)); Edges.Add(FVector(0, 1, 1));
					Edges.Add(FVector(0, 0, 1)); Edges.Add(FVector(1, 0, 1));
					Edges.Add(FVector(1, 0, 1)); Edges.Add(FVector(1, 1, 1));
					Edges.Add(FVector(0, 1, 1)); Edges.Add(FVector(1, 1, 1));

					Edges.Add(FVector(0, 0, 1)); Edges.Add(FVector(0, 0, 0));
					Edges.Add(FVector(0, 1, 1)); Edges.Add(FVector(0, 1, 0));
					Edges.Add(FVector(1, 0, 1)); Edges.Add(FVector(1, 0, 0));
					Edges.Add(FVector(1, 1, 1)); Edges.Add(FVector(1, 1, 0));

					FVector ClosestPoint;
					float ClosestDist = MAX_flt;

					FTransform RefTransform = RefActor.ActorTransform;

					for (int i = 0, Count = Edges.Num(); i < Count; i += 2)
					{
						FVector LineStart = RefTransform.TransformPosition(Math::VLerp(Bounds.Min, Bounds.Max, Edges[i]));
						FVector LineEnd = RefTransform.TransformPosition(Math::VLerp(Bounds.Min, Bounds.Max, Edges[i+1]));

						FVector Point = Math::ClosestPointOnLine(LineStart, LineEnd, StartLocation);
						float Dist = Point.Distance(StartLocation);
						if (Dist < ClosestDist)
						{
							ClosestDist = Dist;
							ClosestPoint = Point;
						}
					}

					RefLocation = ClosestPoint;
				}

				Debug::DrawDebugArrow(
					RefLocation,
					Math::Lerp(RefLocation, StartLocation, 0.33),
					RefLocation.Distance(StartLocation) * 4,
					Color,
					10, 0, true
				);

				Debug::DrawDebugArrow(
					Math::Lerp(RefLocation, StartLocation, 0.33),
					Math::Lerp(RefLocation, StartLocation, 0.66),
					RefActor.ActorLocation.Distance(StartLocation) * 4,
					Color,
					10, 0, true
				);

				Debug::DrawDebugLine(
					Math::Lerp(RefLocation, StartLocation, 0.66),
					StartLocation,
					Color,
					10, 0, true
				);
			}
		}
	}

	void UpdateSelection()
	{
		auto CDO = Cast<UActorReferencesUtilityWidget>(UActorReferencesUtilityWidget.DefaultObject);

		bool bSelectionChanged = false;
		auto Selection = Editor::GetSelectedActors();

		if (bFollowSelection || bRequestUpdateSelection || CDO.bRequestUpdateSelection || References.Num() == 0)
		{
			if (Selection.Num() != 0)
			{
				if (Selection.Num() != References.Num())
				{
					bSelectionChanged = true;
				}
				else
				{
					for (int i = 0, Count = Selection.Num(); i < Count; ++i)
					{
						if (Selection[i] != References[i].Actor)
						{
							bSelectionChanged = true;
							break;
						}
					}
				}
			}
		}

		if (bSelectionChanged)
		{
			References.Reset();

			for (auto Actor : Selection)
			{
				FActorReferencesList List;
				List.Actor = Actor;
				References.Add(List);
			}

			UpdateReferencers();
		}

		bRequestUpdateSelection = false;
		CDO.bRequestUpdateSelection = false;
	}

	void UpdateReferencers()
	{
		for (FActorReferencesList& List : References)
		{
			auto Actor = List.Actor.Get();
			List.bReferencedByLevelScript = Blutility::IsEditorActorReferencedByLevelBlueprint(Actor);
			List.Referencers.Reset();

			TArray<AActor> RefActors = Blutility::FindEditorReferencesToActor(Actor, true);
			for (int i = 0, Count = RefActors.Num(); i < Count; ++i)
				List.Referencers.Add(RefActors[i]);
		}
	}
}

class UActorReferencesActions : UScriptActorMenuExtension
{
	default ExtensionPoint = n"ActorViewOptions";
	default SupportedClasses.Add(AActor);

	/**
	 * Show all actors in the level that reference this actor.
	 */
	UFUNCTION(CallInEditor, Meta = (EditorIcon = "ContentBrowser.ReferenceViewer"))
	void FindActorReferences()
	{
		Blutility::OpenEditorUtilityWindow("/Game/Editor/LevelEditor/WBP_ActorReferencesUtilityWidget.WBP_ActorReferencesUtilityWidget");

		auto CDO = Cast<UActorReferencesUtilityWidget>(UActorReferencesUtilityWidget.DefaultObject);
		CDO.bRequestUpdateSelection = true;
	}
}