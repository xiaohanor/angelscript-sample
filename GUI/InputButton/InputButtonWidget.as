event void FOnInputButtonKeyChanged();

class UInputButtonWidget : UHazeInputButton
{
	FKey DisplayedKey;
	EHazePlayerControllerType DisplayedControllerType;

	FOnInputButtonKeyChanged OnDisplayedKeyChanged;

	UPROPERTY(EditAnywhere)
	bool bColorButtonForOwningPlayer = true;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if (bColorButtonForOwningPlayer && IsValid(Player))
			OnChangeButtonColor(Player.GetPlayerUIColor());
	}

	UFUNCTION(BlueprintEvent)
	void OnChangeButtonColor(FLinearColor Color) {}

	UFUNCTION(BlueprintOverride)
	void OnKeyChanged(UHazeInputTextureDataAsset TextureData, EHazeSelectPlayer PlayerType, FKey Key,
					  EHazePlayerControllerType ControllerType)
	{
		if (DisplayedKey != Key || DisplayedControllerType != ControllerType)
		{
			DisplayedKey = Key;
			DisplayedControllerType = ControllerType;
			OnDisplayedKeyChanged.Broadcast();
		}
	}
};