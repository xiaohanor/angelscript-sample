#if EDITOR
class UPrefabDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = APrefabRoot;

	UPrefabAsset PrevAsset;
	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		APrefabRoot PrefabRoot = Cast<APrefabRoot>(GetCustomizedObject());
		if (PrefabRoot == nullptr)
			return;

		PrevAsset = PrefabRoot.PrefabAsset;

		HideCategory(n"HiddenPrefabState");
		AddAllCategoryDefaultProperties(n"Prefab");
		Drawer = AddImmediateRow(n"Prefab");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		APrefabRoot PrefabRoot = Cast<APrefabRoot>(GetCustomizedObject());
		if (PrefabRoot == nullptr)
			return;
		if (Drawer == nullptr || !Drawer.IsVisible())
			return;

		// Refresh details if our preset changes
		if (PrefabRoot.PrefabAsset != PrevAsset)
		{
			PrevAsset = PrefabRoot.PrefabAsset;
			OnAssetChanged();
			ForceRefresh();
			return;
		}

		// Set a nice actor label if we can
		FString LabelTag;
		if (PrefabRoot.PrefabAsset != nullptr)
			LabelTag = PrefabRoot.PrefabAsset.Name.PlainNameString;

		if (!LabelTag.IsEmpty())
		{
			bool bChangeLabel = false;
			FString Label = PrefabRoot.GetActorLabel();
			if (Label.StartsWith("Prefab "))
			{
				bChangeLabel = true;
			}
			else if (Label.StartsWith("PrefabRoot"))
			{
				FString Number = Label.Mid(10);
				if (Number.IsEmpty() || Number.IsNumeric())
					bChangeLabel = true;
			}
			else if (Label.StartsWith(LabelTag+" "))
			{
				bChangeLabel = true;
			}

			if (bChangeLabel)
			{
				FString NewLabel = f"Prefab {LabelTag}";
				if (!Label.StartsWith(NewLabel))
					Editor::SetActorLabelUnique(PrefabRoot, NewLabel+" 1");
			}
		}

		auto Root = Drawer.BeginVerticalBox();
		auto Section = Root.Section();
		auto ButtonBox = Section.HorizontalBox();

		// Create buttons for using the prefab
		if (PrefabRoot.PrefabAsset == nullptr)
		{
			auto SaveButton = ButtonBox
				.SlotHAlign(EHorizontalAlignment::HAlign_Center).SlotFill()
				.BorderBox().HeightOverride(60).MinDesiredWidth(200)
				.Button("💾\nSave New Prefab");

			if (SaveButton)
				SaveNewPrefab();

			if (HasAttachments())
			{
				auto DiscardButton = ButtonBox
					.SlotHAlign(EHorizontalAlignment::HAlign_Center).SlotFill()
					.BorderBox().HeightOverride(60).MinDesiredWidth(200)
					.Button("❌\nDiscard Attachments")
					.Tooltip("Discard all props attached to this prefab without saving them");

				if (DiscardButton)
					DiscardNewPrefab();
			}
		}
		else if (PrefabRoot.PrefabState.bEditable)
		{
			auto SaveButton = ButtonBox
				.SlotHAlign(EHorizontalAlignment::HAlign_Center).SlotFill()
				.BorderBox().HeightOverride(60).MinDesiredWidth(200)
				.Button("💾\nSave Prefab")
				.Tooltip("Save changes made to prefab and stop editing");

			if (SaveButton)
				SavePrefab();

			auto DiscardButton = ButtonBox
				.SlotHAlign(EHorizontalAlignment::HAlign_Center).SlotFill()
				.BorderBox().HeightOverride(60).MinDesiredWidth(200)
				.Button("❌\nDiscard Changes")
				.Tooltip("Discard all changes made to the prefab and stop editing");

			if (DiscardButton)
			{
				EAppReturnType Answer = EAppReturnType::Yes;
				if (Prefab::HasUnsavedChanges(PrefabRoot))
				{
					Answer = FMessageDialog::Open(
						EAppMsgType::YesNo,
						FText::FromString(f"Discard all changes made to prefab {PrefabRoot.GetActorLabel()}?"),
					);
				}

				if (Answer == EAppReturnType::Yes)
				{
					DiscardPrefab();
				}
			}
		}
		else
		{
			auto EditButton = ButtonBox
				.SlotHAlign(EHorizontalAlignment::HAlign_Center).SlotFill()
				.BorderBox().HeightOverride(60).MinDesiredWidth(200)
				.Button("✏\nEdit Prefab");

			if (EditButton)
				StartEditing();
		}

		// Additional butttons for less common actions
		auto ExtraButtonBox = Section
			.HorizontalBox()
			.SlotFill().
			SlotHAlign(EHorizontalAlignment::HAlign_Center)
			.HorizontalBox();

		if (PrefabRoot.PrefabAsset != nullptr)
		{
			auto BreakButton = ExtraButtonBox
				.SlotHAlign(EHorizontalAlignment::HAlign_Center).SlotFill()
				.BorderBox().HeightOverride(34).MinDesiredWidth(165)
				.Button("💔 Break Apart Prefab")
				.Tooltip("Break apart all the meshes in the prefab and place them normally in the level. It will no longer update to changes to the prefab asset.");

			if (BreakButton)
				BreakPrefabs();
		}

		auto HelpButton = ExtraButtonBox
			.SlotHAlign(EHorizontalAlignment::HAlign_Center).SlotFill()
			.BorderBox().HeightOverride(34).MinDesiredWidth(165)
			.Button("❔ Prefab Help")
			.Tooltip("Open the wiki page for help on using prefabs.");

		if (HelpButton)
			PrefabHelp();
	}


	void BreakPrefabs()
	{
		TArray<AActor> SelectedActors = Editor::GetSelectedActors();
		TArray<APrefabRoot> SelectedPrefabs;
		for (AActor Actor : SelectedActors)
		{
			APrefabRoot Prefab = Cast<APrefabRoot>(Actor);
			if (Prefab == nullptr)
				continue;

			SelectedPrefabs.Add(Prefab);
		}

		APrefabRoot CustomizedPrefab = Cast<APrefabRoot>(GetCustomizedObject());
		SelectedPrefabs.AddUnique(CustomizedPrefab);

		TArray<AActor> NewSelection;

		FString PrefabNames;
		if (SelectedPrefabs.Num() == 1)
			PrefabNames = f"{SelectedPrefabs[0].ActorNameOrLabel}";
		else
			PrefabNames = f"{SelectedPrefabs.Num()} selected prefabs";

		auto Answer = FMessageDialog::Open(
			EAppMsgType::YesNo,
			FText::FromString(f"Break apart {PrefabNames}?\n\nIt will stop being a prefab and future changes to the asset will no longer apply to it."),
		);

		if (Answer != EAppReturnType::Yes)
			return;

		FScopedTransaction Transaction("Break Apart Prefab");
		for (auto PrefabRoot : SelectedPrefabs)
		{
			PrefabRoot.Modify();

			if (!PrefabRoot.PrefabState.bEditable)
				PrefabRoot.StartEditing();

			TArray<AActor> Attachments;
			Prefab::GetDirectPrefabDescendants(PrefabRoot, PrefabRoot.RootComponent, Attachments);

			ABrokenPrefabRoot NewRoot;

			const bool bSpawnBrokenPrefabRoot = false;
			if (bSpawnBrokenPrefabRoot)
			{
				NewRoot = ABrokenPrefabRoot::Spawn(PrefabRoot.ActorLocation, PrefabRoot.ActorRotation, Level = PrefabRoot.Level);
				NewRoot.SetActorScale3D(PrefabRoot.ActorScale3D);
				Editor::SetActorLabelUnique(NewRoot, f"Broken {PrefabRoot.PrefabAsset.Name} 1");
			}

			for (auto AttachActor : Attachments)
			{
				AttachActor.Modify();
				AttachActor.RootComponent.Modify();

				if (NewRoot != nullptr)
					AttachActor.AttachToActor(NewRoot, NAME_None, EAttachmentRule::KeepRelative);
				else
					AttachActor.DetachRootComponentFromParent();
			}

			PrefabRoot.DestroyActor();

			if (NewRoot != nullptr)
				NewSelection.Add(NewRoot);
			NewSelection.Append(Attachments);
		}

		Editor::SelectActors(NewSelection);
	}

	void PrefabHelp()
	{
		FPlatformProcess::LaunchURL("http://wiki.hazelight.se/en/Art/Unreal/Prefabs");
	}

	bool HasAttachments()
	{
		APrefabRoot PrefabRoot = Cast<APrefabRoot>(GetCustomizedObject());

		TArray<AActor> Attachments;
		Prefab::GetDirectPrefabDescendants(PrefabRoot, PrefabRoot.RootComponent, Attachments);
		return Attachments.Num() != 0;
	}

	void OnAssetChanged()
	{
		TArray<AActor> SelectedActors = Editor::GetSelectedActors();
		for (AActor Actor : SelectedActors)
		{
			APrefabRoot Prefab = Cast<APrefabRoot>(Actor);
			if (Prefab == nullptr)
				continue;
			if (Prefab.PrefabAsset == nullptr)
			{
				Prefab::DestroyPermanentComponents(Prefab, Prefab.PrefabState);
			}
			else if (!Prefab.PrefabState.bEditable)
			{
				FScopedTransaction Transaction("Prefab Edited");
				Prefab.Modify();
				Prefab.UpdatePrefabToData();
			}
		}
	}

	void SaveNewPrefab()
	{
		FScopedTransaction Transaction("Save Prefab");
		APrefabRoot PrefabRoot = Cast<APrefabRoot>(GetCustomizedObject());
		PrefabRoot.PrefabState.bEditable = true;
		PrefabRoot.SaveChangesAndStopEditing();
	}

	void DiscardNewPrefab()
	{
		FScopedTransaction Transaction("Discard Prefab");
		APrefabRoot PrefabRoot = Cast<APrefabRoot>(GetCustomizedObject());
		PrefabRoot.PrefabState.bEditable = true;
		PrefabRoot.DiscardChangesAndStopEditing();
	}

	void SavePrefab()
	{
		FScopedTransaction Transaction("Save Prefab");
		APrefabRoot PrefabRoot = Cast<APrefabRoot>(GetCustomizedObject());
		PrefabRoot.SaveChangesAndStopEditing();
		Prefab::UpdateAllChangedPrefabsInLevel();
	}

	void DiscardPrefab()
	{
		FScopedTransaction Transaction("Discard Prefab");
		APrefabRoot PrefabRoot = Cast<APrefabRoot>(GetCustomizedObject());
		PrefabRoot.DiscardChangesAndStopEditing();
	}

	void StartEditing()
	{
		APrefabRoot PrefabRoot = Cast<APrefabRoot>(GetCustomizedObject());

		TArray<AActor> CurrentAttachments;
		Prefab::GetDirectPrefabDescendants(PrefabRoot, PrefabRoot.RootComponent, CurrentAttachments);

		TSet<FString> KnownAttachments;
		for (auto Elem : PrefabRoot.PrefabState.EditableActorsInPrefab)
			KnownAttachments.Add(Elem.Value);

		TArray<AActor> UnknownAttachments;
		for (auto Attachment : CurrentAttachments)
		{
			if (!KnownAttachments.Contains(Attachment.GetPathName()))
				UnknownAttachments.Add(Attachment);
		}

		if (UnknownAttachments.Num() != 0)
		{
			FString Message = "Prefab has extra actors attached to it. If you continue editing these will become part of the prefab:\n";
			for (auto Actor : UnknownAttachments)
				Message += f"\n{Actor.GetActorLabel()}";
			Message += "\n\nContinue editing?";
			auto Result = FMessageDialog::Open(EAppMsgType::YesNo, FText::FromString(Message));
			if (Result == EAppReturnType::No)
				return;
		}
		
		FScopedTransaction Transaction("Edit Prefab");
		PrefabRoot.Modify();
		PrefabRoot.StartEditing();

		Editor::SelectActor(PrefabRoot);
	}
}
#endif