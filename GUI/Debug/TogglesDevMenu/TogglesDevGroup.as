delegate void FOnToggleOptionChanged(FName NewState);
struct FHazeDevToggleGroup
{
	FName GroupPath;
	FString GroupTooltip;

	FHazeDevToggleGroup(FHazeDevToggleCategory Category, FName Name, FString Tooltip = "")
	{
		GroupPath = FName(Category.CategoryName + "/" + Name);
		GroupTooltip = Tooltip;
#if !RELEASE
		DevMenu::AddTogglesCategoryAssociation(Category.CategoryName, GroupPath);
		if (!Tooltip.IsEmpty())
			DevMenu::AddDevToggleTooltip(GroupPath, Tooltip);
#endif	
	}

	void MakeVisible() const
	{
#if !RELEASE
		auto NoWarningPlz = UHazeDevToggleSubsystem::Get().GetInternalGroup(GroupPath, true);
#endif
	}

	FName GetCurrentChosenOption() const
	{
#if !RELEASE
		FHazeInternalDevToggleGroup Internal = UHazeDevToggleSubsystem::Get().GetInternalGroup(GroupPath, false);
		bool bNoWarningPlz = true;
		if (bNoWarningPlz)
			return Internal.ChosenOption;
#endif	
		if (DevMenu::GetTogglesGroup(GroupPath).Options.Num() == 0)
			return NAME_None;
		return DevMenu::GetTogglesGroup(GroupPath).Options[0];
	}

	void BindOnChanged(UObject Object, FName FunctionName) const
	{
#if !RELEASE
		FHazeInternalDevToggleGroup& Internal = UHazeDevToggleSubsystem::Get().GetInternalGroup(GroupPath, false);
		Internal.OnChanged.AddUFunction(Object, FunctionName);
#endif	
	}
}

struct FHazeDevToggleOption
{
	FName OptionName;
	FName GroupPath;
	bool bDefault = false;

	FHazeDevToggleOption(FHazeDevToggleGroup Group, FName Name, bool bIsDefaultOption = false)
	{
		OptionName = Name;
		GroupPath = Group.GroupPath;
		bDefault = bIsDefaultOption;
		DevMenu::AddTogglesGroupOption(GroupPath, OptionName, bDefault);
	}

	bool IsEnabled() const
	{
#if !RELEASE
		if (UHazeDevToggleSubsystem::Get().TogglesAddedThisSession.Contains(GroupPath))
		{
			if (UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession.Contains(GroupPath))
				UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession.Remove(GroupPath);

			bool bDefaultSelection = UHazeDevToggleSubsystem::Get().ToggleGroups[GroupPath].ChosenOption == NAME_None;
			if (bDefaultSelection)
				return UHazeDevToggleSubsystem::Get().ToggleGroups[GroupPath].Options[0] == OptionName;
			else
				return UHazeDevToggleSubsystem::Get().ToggleGroups[GroupPath].ChosenOption == OptionName;
		}
		else if (!UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession.Contains(GroupPath))
		{
			UHazeDevToggleSubsystem::Get().TogglesCalledButNotAddedThisSession.Add(GroupPath);
			UHazeDevToggleSubsystem::Get().bDirty = true;
		}
			
#endif
		return DevMenu::GetTogglesGroup(GroupPath).Options[0] == OptionName;
		//return bDefault; // we dont require a default item atm. Then it will default to first constructed Option
	}
}
