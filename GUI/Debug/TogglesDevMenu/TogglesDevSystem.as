event void FOnDevToggleBooleanChanged(bool bNewState);
event void FOnDevToggleOptionChanged(FName NewState);

struct FHazeInternalDevToggleBool
{
	bool bState = false;
	FString Tooltip;
	FOnDevToggleBooleanChanged OnChanged;
};

struct FHazeInternalDevToggleGroup
{
	TArray<FName> Options;
	FName ChosenOption = NAME_None;
	FString Tooltip;
	bool bMakeVisibleThisSession = false;
	FOnDevToggleOptionChanged OnChanged;
}

class UHazeDevToggleSubsystem : UEngineSubsystem
{
	access ToggleSystem = private, UTogglesDevMenu, UTogglesDevMenuEntryWidget, UTogglesDevMenuOptionTileWidget, UTogglesDevPresetEntryWidget, 
									FHazeDevToggleCategory, FHazeDevToggleGroup, FHazeDevToggleOption, FHazeDevToggleBool, FHazeDevToggleBoolPerPlayer, FHazeDevTogglePreset;
	access:ToggleSystem const FName LevelSpecificCategory = n"Level Specific";
	access:ToggleSystem const FString CharOptionDivider = "@";

	access:ToggleSystem TMap<FName, FHazeInternalDevToggleBool> Toggles;
	access:ToggleSystem TMap<FName, FHazeInternalDevToggleGroup> ToggleGroups;
	access:ToggleSystem TMap<FName, FName> Tooltips;
	access:ToggleSystem TSet<FName> TogglesAddedThisSession;
	access:ToggleSystem TSet<FName> TogglesCalledButNotAddedThisSession;
	access:ToggleSystem TArray<FName> ChosenCategories;
	access:ToggleSystem bool bDirty = false;

	bool IsGenericCategory(FName CategoryPath) const
	{
		if (CategoryPath == HiddenDevToggleStatics::DevPrintCategory.CategoryName)
			return true;
		if (CategoryPath == DevTogglesMovement::MovementCategory.CategoryName)
			return true;
		if (CategoryPath == DevTogglesPlayerHealth::PlayerHealth.CategoryName)
			return true;
		if (CategoryPath == PlayerInputDevToggles::PlayerInputCategory.CategoryName)
			return true;
		if (CategoryPath == DevTogglesTimeDilation::TimeDilationCategory.CategoryName)
			return true;
		if (CategoryPath == ForceFeedbackDevToggles::ForceFeedbackCategory.CategoryName)
			return true;
		return false;
	}

#if !RELEASE
	void ShowGenericGameCategories() const
	{
		HiddenDevToggleStatics::DevPrintCategory.MakeVisible();
		DevTogglesPlayerHealth::PlayerHealth.MakeVisible();
		DevTogglesMovement::MovementCategory.MakeVisible();
		PlayerInputDevToggles::PlayerInputCategory.MakeVisible();
		DevTogglesTimeDilation::TimeDilationCategory.MakeVisible();
		DevTogglesTimeDilation::ToggledTimeDilation.MakeVisible();
		ForceFeedbackDevToggles::ForceFeedbackCategory.MakeVisible();
	}

	const TMap<FName, FHazeInternalDevToggleGroup> & GetToggleGroups() { return ToggleGroups; }
	const TMap<FName, FHazeInternalDevToggleBool> & GetToggles() { return Toggles; }

	void PrintCategoryString(FName CategoryName, FString PrintString, float Duration, FLinearColor Color, float TextScale)
	{
		FName TogglePath = FName(HiddenDevToggleStatics::DevPrintCategory.CategoryName + "/" + CategoryName);
		if (!Toggles.Contains(TogglePath))
		{
			FHazeDevToggleBool SetupBoolean = FHazeDevToggleBool(HiddenDevToggleStatics::DevPrintCategory, CategoryName);
			FHazeInternalDevToggleBool& NoWarnignPlz = GetInternalBool(TogglePath, true);
		}
		else if (Toggles[TogglePath].bState)
		{
			FString Stringy = "[" + CategoryName.ToString() + "] " + PrintString;
			PrintToScreenScaled(Stringy, Duration, Color, TextScale);
		}
	}

	access:ToggleSystem void MakeCategoryToggleVisible(FName TogglePath)
	{
		if (DevMenu::IsToggleGroup(TogglePath))
			GetInternalGroup(TogglePath, true);
		else
			GetInternalBool(TogglePath, true);
	}

	access:ToggleSystem FHazeInternalDevToggleBool& GetInternalBool(FName TogglePath, bool bAddThisSession = false)
	{
		if (bAddThisSession)
		{
			TogglesAddedThisSession.Add(TogglePath);
			TogglesCalledButNotAddedThisSession.Remove(TogglePath);
		}
		else if (!TogglesAddedThisSession.Contains(TogglePath) && !TogglesCalledButNotAddedThisSession.Contains(TogglePath))
		{
			TogglesCalledButNotAddedThisSession.Add(TogglePath);
			bDirty = true;
		}
		if (Toggles.Contains(TogglePath))
			return Toggles[TogglePath];
		FHazeInternalDevToggleBool Toggle;
		Toggle.Tooltip = DevMenu::GetDevToggleTooltip(TogglePath);
		Toggle.bState = false;
		Toggles.Add(TogglePath, Toggle);
		bDirty = true;
		return Toggles[TogglePath];
	}

	access:ToggleSystem FHazeInternalDevToggleGroup& GetInternalGroup(FName GroupPath, bool bAddThisSession = false)
	{
		if (AddGroupOptions(GroupPath))
			bDirty = true;
		if (bAddThisSession)
		{
			TogglesAddedThisSession.Add(GroupPath);
			ToggleGroups[GroupPath].bMakeVisibleThisSession = true;
			bDirty = true;
		}
		return ToggleGroups[GroupPath];
	}

	private bool AddGroupOptions(FName GroupPath)
	{
		if (ToggleGroups.Contains(GroupPath))
			return false;

		if (!ToggleGroups.Contains(GroupPath))
			ToggleGroups.Add(GroupPath, FHazeInternalDevToggleGroup());
		FHazeInternalDevToggleGroup& Group = ToggleGroups[GroupPath];
		Group.Tooltip = DevMenu::GetDevToggleTooltip(GroupPath);

		Group.Options.Reset(Group.Options.Num() + 1);
		FHazeCachedDevToggleGroup GroupInfo = DevMenu::GetTogglesGroup(GroupPath);
		for (auto OptionName : GroupInfo.Options)
			Group.Options.AddUnique(OptionName);

		if (!Group.Options.Contains(Group.ChosenOption)) // in case of removing the chosen option
			Group.ChosenOption = NAME_None;
		return true;
	}
#endif
};