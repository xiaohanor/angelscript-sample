
struct FTogglesDevPresetEntryData
{
	FName Path;
	FName Name;
	bool bIsSearching = false;
	bool bDirty = true;
};

UCLASS(Abstract)
class UTogglesDevPresetEntryWidget : UHazeUserWidget
{
	FTogglesDevPresetEntryData EntryData;
	bool bHasOptions = false;

	UPROPERTY(BindWidget)
	UHorizontalBox TheBox;

	UPROPERTY(BindWidget)
	UButton DoTheThingButton;
	UPROPERTY(BindWidget)
	UTextBlock PresetName;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DoTheThingButton.OnClicked.AddUFunction(this, n"OnClicked");
	}

	UFUNCTION()
	private void OnClicked()
	{
#if !RELEASE
		EntryData.bDirty = true;
		TMap<FName, FHazeToggleInternalPreset> Presets = DevMenu::GetDevTogglePresets();
		FHazeToggleInternalPreset PresetData = Presets[EntryData.Path];
		for (const FName& BooleanPath : PresetData.ToggleBooleanPaths)
		{
			if (UHazeDevToggleSubsystem::Get().Toggles[BooleanPath].bState != true)
			{
				UHazeDevToggleSubsystem::Get().Toggles[BooleanPath].bState = true;
				UHazeDevToggleSubsystem::Get().Toggles[BooleanPath].OnChanged.Broadcast(true);
			}
		}
		for (const FName& OptionPath : PresetData.ToggleOptionPaths)
		{
			TArray<FString> PathPieces;
			OptionPath.ToString().ParseIntoArray(PathPieces, UHazeDevToggleSubsystem::Get().CharOptionDivider);
			FName GroupPath = FName(PathPieces[0]);
			FName OptionName = FName(PathPieces[1]);
			
			FHazeInternalDevToggleGroup& InternalGroup = UHazeDevToggleSubsystem::Get().ToggleGroups[GroupPath];
			if (InternalGroup.ChosenOption != OptionName)
			{
				InternalGroup.ChosenOption = OptionName;
				InternalGroup.OnChanged.Broadcast(OptionName);
			}
		}
		UHazeDevToggleSubsystem::Get().bDirty = true;
#endif
	}

	UFUNCTION()
	void SetEntryData(FTogglesDevPresetEntryData NewData)
	{
		EntryData = NewData;
		PresetName.Text = FText::FromString(NewData.Name.ToString());
		DoTheThingButton.SetToolTipText(FText::FromString(DevMenu::GetDevToggleTooltip(EntryData.Path)));
		EntryData.bDirty = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (EntryData.bDirty)
			SetEntryData(EntryData);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		return FEventReply::Handled().SetUserFocus(DoTheThingButton, InFocusEvent.Cause);
	}
};
