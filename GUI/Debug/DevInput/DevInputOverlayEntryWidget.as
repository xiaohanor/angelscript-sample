UCLASS(Abstract)
class UDevInputOverlayEntryWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTextBlock NameLabel;

	UPROPERTY(BindWidget)
	UTextBlock StatusLabel;

	FHazeDevInputInfo DevInputInfo;

	void SetFromInputInfo(bool bGamepad, FHazeDevInputInfo Info)
	{
		DevInputInfo = Info;

		for(auto Key : Info.Keys)
		{
			if (Key.IsGamepadKey() != bGamepad)
				continue;

			AddInputButton(Key);
		}

		NameLabel.SetText(FText::FromName(Info.Name));
	}

	UFUNCTION(BlueprintEvent)
	void AddInputButton(FKey Key) {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		FString StatusDescription;
		FLinearColor StatusColor;

		DevInputInfo.GetStatus(StatusDescription, StatusColor);

		if (StatusDescription.Len() != 0)
		{
			StatusLabel.SetText(FText::FromString(StatusDescription));
			StatusLabel.SetColorAndOpacity(StatusColor);
			StatusLabel.SetVisibility(ESlateVisibility::HitTestInvisible);
		}
		else
		{
			StatusLabel.SetText(FText());
			StatusLabel.SetVisibility(ESlateVisibility::Hidden);
		}
	}
}