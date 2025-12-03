class UHazeActorSpawnerDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AHazeActorSpawnerBase;

	AHazeActorSpawnerBase Spawner;
	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Spawner = Cast<AHazeActorSpawnerBase>(GetCustomizedObject());
		if (GetCustomizedObject().World == nullptr)
		{
			// In BP (CDO does not have a world). You'll have to add patterns the usual way! 
			HideCategory(n"EditorSpawnPatterns");
			return;
		}
		else 
		{
			// Placed instance
			Drawer = AddImmediateRow(n"EditorSpawnPatterns");
			EditCategory(n"EditorSpawnPatterns", "Spawn Patterns", EScriptDetailCategoryType::Transform);
			HideCategory(n"Activation");
			if (ObjectsBeingCustomized.Num() > 1)
				HideProperty(n"AddPattern");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (GetCustomizedObject().World == nullptr)
		{
			// In BP (CDO does not have a world). You'll have to add patterns the usual way! 
			return;
		}

		if (Spawner == nullptr)
			return;

		if (!Drawer.IsVisible())
			return;

		auto Section = Drawer.Begin();
		if (ObjectsBeingCustomized.Num() > 1)
		{
			Section.Text("Multiple spawners selected.").Color(FLinearColor::Gray).Bold();
			Drawer.End();
			return;
		}

		TArray<UHazeActorSpawnPattern> Patterns;
		TArray<int> ActivationLevels;
		FString ActivationLevelIndent = "";
		Spawner.GetComponentsByClass(Patterns);
		SortPatterns(Patterns, ActivationLevels);
		for (int i = 0; i < Patterns.Num(); i++)
		{
			FString Caption = GetCaption(Patterns[i]);
			auto Box = Section.HorizontalBox();

			if (ActivationLevels[i] != 0)
			{
				if (ActivationLevels[i] == -1)
					ActivationLevelIndent = "<external activation> ";
				else if (ensure(i > 0) && (ActivationLevels[i] > ActivationLevels[i-1]))					
					ActivationLevelIndent = (ActivationLevels[i] == 1) ? " |__ " : "         " + ActivationLevelIndent;
				Box.Text(ActivationLevelIndent).Color(FLinearColor::Gray);
			}

			auto SelectButton = Box.Button(Caption).Padding(2.0);
			if (IsSelectedPattern(Patterns[i]))
				SelectButton.BackgroundColor(FLinearColor(0.0, 0.2, 0.4, 1.0)); 
			if (SelectButton)
			{
				Editor::SelectComponent(Patterns[i]);
				ForceRefresh();
			}
			if (Editor::GetCompnentCreationMethod(Patterns[i]) == EComponentCreationMethod::Instance)
			{
				// We should be able to remove instance added patterns
				if (Box.Button("-").Padding(1.0))
				{
					Patterns[i].DestroyComponent(Patterns[i].Owner);
					ForceRefresh();
					Editor::SelectActor(nullptr);
					Editor::SelectActor(Spawner);
				}
			}
			else
			{
				// ... but patterns added in class script/bp are permanent
				Box.SlotPadding(7.0).Text("(Inherited)").Scale(0.8);
			}
		}

		// Combo box to add new patterns with 
		auto NewPatternBox = Section.HorizontalBox();
		NewPatternBox.Text("Add Pattern   ").Color(FLinearColor::Gray);
		TArray<UClass> SpawnPatternClasses = UClass::GetAllSubclassesOf(UHazeActorSpawnPattern);
		TArray<FName> SpawnPatternClassNames;
		for (UClass PatternClass : SpawnPatternClasses)
		{
			UHazeActorSpawnPattern CDO = Cast<UHazeActorSpawnPattern>(PatternClass.DefaultObject);
			if(CDO != nullptr && CDO.bLevelSpecificPattern && !Spawner.bShowLevelSpecificPatterns)
				continue;
			FString DisplayName = PatternClass.Name.ToString();
			DisplayName.RemoveFromStart("HazeActorSpawnPattern");
			SpawnPatternClassNames.Add(FName(DisplayName));
		}
		auto NewPatternComboBox = NewPatternBox.ComboBox().Items(SpawnPatternClassNames);
		if (SpawnPatternClasses.IsValidIndex(NewPatternComboBox.SelectedIndex))
		{
			// Add new pattern
			UActorComponent NewPattern = Editor::AddInstanceComponentInEditor(Spawner, SpawnPatternClasses[NewPatternComboBox.SelectedIndex], NAME_None);
			NewPatternComboBox.Value(NAME_None);
			ForceRefresh();
			Editor::SelectComponent(NewPattern);
		}

		Drawer.End();

		// Set visualization order of patterns, lowest to last pattern
		int VisualizationOrder = 0;
		for (int i = Patterns.Num() - 1; i >= 0; i--)
		{
			if (!Patterns[i].bCanEverSpawn)
			{
				Patterns[i].VisualOffsetOrder = VisualizationOrder;
				VisualizationOrder++;
			}
		}
	}	

	FString GetCaption(UHazeActorSpawnPattern Pattern)
	{
		return HazeActorSpawnerDetails::GetCaption(Pattern);
	}

	bool IsSelectedPattern(UHazeActorSpawnPattern Pattern)
	{
		return false;
	}

	void SortPatterns(TArray<UHazeActorSpawnPattern>& Patterns, TArray<int>& ActivationLevels)
	{
		// Patterns that start active first, those activated by other patterns follow recursively
		TArray<UHazeActorSpawnPattern> Unsorted = Patterns;
		Patterns.Empty(Unsorted.Num());
		TArray<UHazeActorSpawnPattern> Starting;
		TArray<UHazeActorSpawnPattern> Remaining;
		for (UHazeActorSpawnPattern Pattern : Unsorted)
		{
			if (Pattern.ShouldStartActive())
				Starting.Add(Pattern);
			else
				Remaining.Add(Pattern);
		}
		SortPatternsRecursive(Patterns, Starting, Remaining, ActivationLevels);
	}

	void SortPatternsRecursive(TArray<UHazeActorSpawnPattern>& Sorted, TArray<UHazeActorSpawnPattern>& Current, TArray<UHazeActorSpawnPattern>& Remaining, TArray<int>& ActivationLevels)
	{
		int CurrentIndent = (ActivationLevels.Num() == 0) ? 0 : ActivationLevels.Last() + 1;

		if (Current.Num() == 0)
		{
			// We only have externally activated patterns left
			Current = Remaining;
			Remaining.Empty();
			CurrentIndent = -1;
		}

		// Sort current patterns on activation grouping with spawning patterns first, 
		// non-spawners after and internal activation patterns last
		TArray<UHazeActorSpawnPattern> NonSpawners;
		TArray<UHazeActorSpawnPattern> Activators;
		for (UHazeActorSpawnPattern Pattern : Current)
		{
			UHazeActorSpawnPatternActivateOwnPatterns Activator = Cast<UHazeActorSpawnPatternActivateOwnPatterns>(Pattern);
			if ((Activator != nullptr) && (Activator.PatternsToActivate.Num() > 0))
				Activators.Add(Pattern);
			else if (!Pattern.bCanEverSpawn)
				NonSpawners.Add(Pattern);
			else
				Sorted.Add(Pattern);
		}
		Sorted.Append(NonSpawners);
		Sorted.Append(Activators);
		ActivationLevels.Reserve(Sorted.Num());
		for (int i = ActivationLevels.Num(); i < Sorted.Num(); i++)
		{
			ActivationLevels.Add(CurrentIndent);
		}

		// Find patterns that are activated by current patterns
		if (Remaining.Num() > 0)
		{
			TArray<UHazeActorSpawnPattern> Next;
			for (UHazeActorSpawnPattern Pattern : Activators)
			{
				UHazeActorSpawnPatternActivateOwnPatterns Activator = Cast<UHazeActorSpawnPatternActivateOwnPatterns>(Pattern);
				for (UHazeActorSpawnPattern Activated : Activator.PatternsToActivate)
				{
					int iActivated = Remaining.FindIndex(Activated);
					if (Remaining.IsValidIndex(iActivated))
					{
						Next.Add(Activated);
						Remaining.RemoveAt(iActivated);
					}
				} 
			}
			SortPatternsRecursive(Sorted, Next, Remaining, ActivationLevels);
		}
	}
}

class UHazeActorSpawnPatternDetailCustomization : UHazeActorSpawnerDetailCustomization
{
	default DetailClass = UHazeActorSpawnPattern;
	
	UHazeActorSpawnPattern SelectedPattern;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails() 
	{
		Super::CustomizeDetails();
		if (GetCustomizedObject().World == nullptr)
		{
			// In BP (CDO does not have a world). You'll have to add patterns the usual way! 
			HideCategory(n"EditorSpawnPatterns");
		}
		else
		{
			// Placed instance
			SelectedPattern = Cast<UHazeActorSpawnPattern>(GetCustomizedObject());
			Spawner = Cast<AHazeActorSpawnerBase>(SelectedPattern.Owner);
			EditCategory(n"SpawnPattern", GetCaption(SelectedPattern) + " Spawn Pattern", EScriptDetailCategoryType::Default);
			EditCategory(n"Preview", "Preview", EScriptDetailCategoryType::Default);
		}
	}

	bool IsSelectedPattern(UHazeActorSpawnPattern Pattern) override
	{
		return (Pattern == SelectedPattern);
	}
}

class UHazeActorSpawnPatternEntryAnimationDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = UHazeActorSpawnPatternEntryAnimation;

	float PrevPreview = -1.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
#if EDITOR
		if (GetCustomizedObject().World == nullptr)
			return;

		// Make sure animation updates when sliding preview fraction
		UHazeActorSpawnPatternEntryAnimation EntryAnimPattern = Cast<UHazeActorSpawnPatternEntryAnimation>(GetCustomizedObject());
		if (PrevPreview != EntryAnimPattern.PreviewFraction)
		{
			// We only need to update preview mesh, destination preview will never move.
			UpdatePreviewMesh(EntryAnimPattern, EntryAnimPattern.PreviewMeshComp); 
			PrevPreview = EntryAnimPattern.PreviewFraction;
		}
#endif
	}

	void UpdatePreviewMesh(UHazeActorSpawnPatternEntryAnimation EntryAnimPattern, UHazeEditorPreviewSkeletalMeshComponent PreviewMeshComp)
	{
#if EDITOR
		if (PreviewMeshComp == nullptr)
			return;
		UAnimSequence Anim = Cast<UAnimSequence>(PreviewMeshComp.AnimationData.AnimToPlay);
		if (Anim == nullptr)
			return;

		float AnimTime = EntryAnimPattern.PreviewFraction * Anim.PlayLength;
		if ((Anim != nullptr) && !Math::IsNearlyEqual(PreviewMeshComp.AnimationData.SavedPosition, AnimTime, KINDA_SMALL_NUMBER))
			PreviewMeshComp.SetAnimationPreview(Anim, AnimTime, true);
#endif
	}
}

class UHazeActorSpawnPatternActivateOwnPatternsDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = UHazeActorSpawnPatternActivateOwnPatterns;

	UHazeImmediateDrawer PattersToActivateDrawer;
	UHazeActorSpawnPatternActivateOwnPatterns ActivationPattern;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails() 
	{
		if (GetCustomizedObject().World == nullptr)
			return;
		
		ActivationPattern = Cast<UHazeActorSpawnPatternActivateOwnPatterns>(GetCustomizedObject());
		PattersToActivateDrawer = AddImmediateRow(n"SpawnPattern");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if ((PattersToActivateDrawer == nullptr) || (ActivationPattern == nullptr))
			return;
		if (!PattersToActivateDrawer.IsVisible()) 
			return;

		// Clean up patterns to activate
		for (int i = ActivationPattern.PatternsToActivate.Num() - 1; i >= 0; i--)
		{
			if (ActivationPattern.PatternsToActivate[i] == nullptr)
				ActivationPattern.PatternsToActivate.RemoveAt(i);
		}

		auto Section = PattersToActivateDrawer.Begin();

		if (ActivationPattern.PatternsToActivate.Num() > 0)
			Section.Text("Patterns to activate");
		for (int i = 0; i < ActivationPattern.PatternsToActivate.Num(); i++)
		{
			auto Row = Section.HorizontalBox();
			UHazeActorSpawnPattern RowPattern = ActivationPattern.PatternsToActivate[i];
			if (!ensure(RowPattern != nullptr))
				continue;

			// Show pattern caption. Clicking on it will select pattern.
			if (Row.Button(GetCaption(RowPattern)).Padding(2.0).BackgroundColor(FLinearColor(0.05, 0.2, 0.05, 1.0)))
			{
				Editor::SelectComponent(RowPattern);
				ForceRefresh();
			}
			
			// Button to remove entry from list
			if (Row.Button("-").Padding(1.0))
			{
				ActivationPattern.PatternsToActivate.RemoveAt(i);
				break;
			}
			Row.Text("  Start Active ").Scale(0.9).Color(FLinearColor::Gray);
			auto StartActiveCheckBox = Row.CheckBox().Checked(RowPattern.bStartActive);
			RowPattern.bStartActive = StartActiveCheckBox;
		}

		// Combo box to add patterns to activate
		{
			auto Row = Section.HorizontalBox();
			Row.Text("Select Pattern To Activate ").Scale(0.9).Color(FLinearColor::Gray);
			TArray<FName> AvailablePatternsToAdd;
			AvailablePatternsToAdd.Add(NAME_None);
			TArray<UHazeActorSpawnPattern> Patterns;
			TMap<FName, UHazeActorSpawnPattern> PatternsByCaption;
			ActivationPattern.Owner.GetComponentsByClass(Patterns);
			for (UHazeActorSpawnPattern Pattern : Patterns)
			{
				if (Pattern == ActivationPattern)
					continue;
				if (ActivationPattern.PatternsToActivate.Contains(Pattern))
					continue;
				FName PatternCaption = FName(GetCaption(Pattern));
				AvailablePatternsToAdd.Add(PatternCaption);
				PatternsByCaption.Add(PatternCaption, Pattern);
			}
			auto ComboBox = Row.ComboBox().Items(AvailablePatternsToAdd);
			ComboBox.Value(NAME_None); // Reset selected item
			if (!ComboBox.SelectedItem.IsNone() && ensure(PatternsByCaption.Contains(ComboBox.SelectedItem)))
			{
				UHazeActorSpawnPattern NewPatterToActivate = PatternsByCaption[ComboBox.SelectedItem];
				ActivationPattern.PatternsToActivate.AddUnique(NewPatterToActivate);
				NewPatterToActivate.bStartActive = false;
			}
		}

		PattersToActivateDrawer.End();
	}

	FString GetCaption(UHazeActorSpawnPattern Pattern)
	{
		return HazeActorSpawnerDetails::GetCaption(Pattern);
	}
}

namespace HazeActorSpawnerDetails
{
	FString GetCaption(UHazeActorSpawnPattern Pattern)
	{
		FString Caption = GetCaption(Pattern.Name);
		if (!Pattern.bCanEverSpawn)
			return Caption;
		TArray<TSubclassOf<AHazeActor>> Classes;
		Pattern.GetSpawnClasses(Classes);
		for (TSubclassOf<AHazeActor> Class : Classes)
		{
			if (!Class.IsValid())	
				continue;
			FString Name = "" + Class.Get().Name;
			return Caption + " (" + Name.LeftChop(2) + ")";			
		}
		return Caption + " (None)";
	}

	FString GetCaption(FName PatternName)
	{
		FString PatternDesc = PatternName.ToString();
		PatternDesc.RemoveFromStart("HazeActor");
		PatternDesc.RemoveFromStart("SpawnPattern");
		if (PatternDesc.Len() == 0)
			return PatternName.ToString();

		// Add empty spaces before upper case letters (except first)
		FString Caption;
		int Start = 0;
		for (int i = 1; i < PatternDesc.Len(); i++)
		{
			// ASCII compare for upper case letters A-Z :P
			if ((PatternDesc[i] > 64) && (PatternDesc[i] < 91))
			{
				Caption += PatternDesc.Mid(Start, i - Start) + " ";				
				Start = i;
			}
		}
		if (Start < PatternDesc.Len())
			Caption += PatternDesc.Right(PatternDesc.Len() - Start);

		return Caption;
	}
}


