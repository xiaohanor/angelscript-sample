#if EDITOR
const FConsoleCommand Command_ConvertSelectionToPrefab("Haze.ConvertSelectionToPrefab",n"Console_ConvertSelectionToPrefab");
local void Console_ConvertSelectionToPrefab(TArray<FString> Arguments)
{
	FScopeDebugEditorWorld EditorWorld;
	auto Subsys = UPrefabEditorSubsystem::Get();
	Subsys.ConvertSelectionToPrefab();
}

class UPrefabEditorSubsystem : UHazePrefabEditorSubsystem
{
	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Deinitialize()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsChanged()
	{
		Prefab::UpdateAllChangedPrefabsInLevel();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		auto Overlay = GetEditorViewportOverlay();
		if (!Overlay.IsVisible())
			return;

		auto Canvas = Overlay.BeginCanvasPanel();
		if (Editor::IsPlaying())
			return;

		auto EditorActorSubsystem = UEditorActorSubsystem::Get();
		TArray<AActor> SelectedActors = EditorActorSubsystem.GetSelectedLevelActors();

		// De-select actors underneath uneditable prefabs, they can't be changed
		/*for (AActor Actor : SelectedActors)
		{
			auto InsidePrefab = Prefab::GetAttachedPrefab(Actor);
			if (InsidePrefab != nullptr && InsidePrefab != Actor)
			{
				if(!Prefab::CanEditPrefabChildren(InsidePrefab))
				{
					EditorActorSubsystem.SetActorSelectionState(Actor, false);
					EditorActorSubsystem.SetActorSelectionState(InsidePrefab, true);
				}
			}
		}*/

		// Show edit UI for all prefabs in editing mode
		auto ExistingPrefabs = Editor::GetAllEditorWorldActorsOfClass(APrefabRoot);

		float Y = 30;
		for (auto It : ExistingPrefabs)
		{
			auto Prefab = Cast<APrefabRoot>(It);
			if (!Prefab.PrefabState.bEditable && !(Prefab.PrefabAsset == nullptr && Prefab::HasAttachments(Prefab)))
				continue;

			FLinearColor BorderColor = FLinearColor::MakeFromHex(0xff1a1a1a);

			bool bSelected = false;
			if (Editor::IsSelected(Prefab))
			{
				bSelected = true;
			}
			else
			{
				for (auto Selected : SelectedActors)
				{
					if (Selected.RootComponent != nullptr && Selected.RootComponent.IsAttachedTo(Prefab))
					{
						bSelected = true;
						break;
					}
				}
			}

			auto BackgroundBox = Canvas
				.SlotAnchors(0.5, 0.0)
				.SlotAlignment(0.5, 0.0)
				.SlotOffset(0.0, Y, 0.0, 0.0)
				.SlotAutoSize(true)

				.BorderBox()
				.MinDesiredWidth(850)
				.MinDesiredHeight(30)
				.BackgroundColor(BorderColor)

				.BorderBox()
			;

			if (BackgroundBox.WasClicked())
			{
				Editor::SelectActor(Prefab);
			}

			if (bSelected)
			{
				BackgroundBox.BackgroundColor(FLinearColor::MakeFromHex(0xff0a35af, false));
			}
			else if (BackgroundBox.IsHovered() && !bSelected)
			{
				BackgroundBox.BackgroundColor(FLinearColor::MakeFromHex(0xff1a1a31, false));
			}
			else
			{
				BackgroundBox.BackgroundColor(FLinearColor::MakeFromHex(0xff1a1a1a, false));
			}

			auto ButtonBox = BackgroundBox.HorizontalBox();
			ButtonBox
				.SlotPadding(10, 4, 2, 2)
				.SlotVAlign(EVerticalAlignment::VAlign_Center)
				.Text("Editing Prefab: ")
				.Scale(1.2)
				.Color(FLinearColor::MakeFromHex(0xffaaaaaa))
				.ShadowColor(FLinearColor::Black)
				.ShadowOffset(FVector2D(1.0, 1.0));
			ButtonBox
				.SlotFill()
				.SlotPadding(2, 4, 25, 2)
				.SlotVAlign(EVerticalAlignment::VAlign_Center)
				.Text(Prefab.GetActorLabel())
				.Scale(1.2)
				.ShadowColor(FLinearColor::Black)
				.ShadowOffset(FVector2D(1.0, 1.0));

			if (Prefab.PrefabAsset == nullptr)
			{
				if (ButtonBox.Button("💾 Save New Prefab").Padding(5))
				{
					FScopedTransaction Transaction("Save New Prefab");
					Prefab.PrefabState.bEditable = true;
					Prefab.SaveChangesAndStopEditing();
					Prefab::UpdateAllChangedPrefabsInLevel();
				}
			}
			else
			{
				if (ButtonBox.Button("💾 Save Changes").Padding(5))
				{
					FScopedTransaction Transaction("Save Prefab");
					Prefab.SaveChangesAndStopEditing();
					Prefab::UpdateAllChangedPrefabsInLevel();
					if (bSelected)
						Editor::SelectActor(Prefab);
				}

				if (ButtonBox.Button("❌ Discard Changes").Padding(5))
				{
					EAppReturnType Answer = EAppReturnType::Yes;
					if (Prefab::HasUnsavedChanges(Prefab))
					{
						Answer = FMessageDialog::Open(
							EAppMsgType::YesNo,
							FText::FromString(f"Discard all changes made to prefab {Prefab.GetActorLabel()}?"),
						);
					}

					if (Answer == EAppReturnType::Yes)
					{
						FScopedTransaction Transaction("Discard Prefab");
						Prefab.DiscardChangesAndStopEditing();

						if (bSelected)
							Editor::SelectActor(Prefab);
					}
				}
			}

			Y += 45;
		}
	}

	void ConvertSelectionToPrefab()
	{
		ULevelEditorSubsystem LevelEditor = ULevelEditorSubsystem::Get();
		ULevel Level = LevelEditor.CurrentLevel;

		FVector Location;

		TArray<AActor> Actors = Editor::GetSelectedActors();
		for (int i = Actors.Num() - 1; i >= 0; --i)
		{
			if (!IsValid(Actors[i]))
				Actors.RemoveAt(i);

			if (Actors[i].Level != Level)
			{
				FMessageDialog::Open(EAppMsgType::Ok,
					FText::FromString(f"Cannot make prefab: {Actors[i].ActorNameOrLabel} is not in the current level"));
				return;
			}

			Location += Actors[i].ActorLocation;
		}
		Location /= float(Actors.Num());

		auto Prefab = SpawnActor(APrefabRoot, Location, Level = Level);
		for (AActor Actor : Actors)
			Actor.AttachToActor(Prefab, NAME_None, EAttachmentRule::KeepWorld);

		Editor::SelectActor(Prefab);
	}
};
#endif