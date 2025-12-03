class UPlayerToggleInvertDevInput : UHazeDevInputHandler
{
	default Name = n"Toggle Inverted Camera";
	default Category = n"Settings";
	default bTriggerLocalOnly = true;

	default AddKey(EKeys::Gamepad_FaceButton_Bottom);
	default AddKey(EKeys::Q);

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		FName InvertSetting;

		if (PlayerOwner.IsMio())
			InvertSetting = n"InvertCameraMio";
		else
			InvertSetting = n"InvertCameraZoe";

		FString InvertValue;
		GameSettings::GetGameSettingsValue(InvertSetting, InvertValue);

		if (InvertValue == "On")
			GameSettings::SetGameSettingsValue(InvertSetting, "Off");
		else
			GameSettings::SetGameSettingsValue(InvertSetting, "On");
	}

	UFUNCTION(BlueprintOverride)
	void GetStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		FString SettingValue;
		if (PlayerOwner.IsMio())
			GameSettings::GetGameSettingsValue(n"InvertCameraMio", SettingValue);
		else
			GameSettings::GetGameSettingsValue(n"InvertCameraZoe", SettingValue);

		if (SettingValue == "On")
		{
			OutDescription = "[ Invert: ON ]";
			OutColor = FLinearColor::Green;
		}
		else
		{
			OutDescription = "[ Invert: OFF ]";
			OutColor = FLinearColor::Red;
		}
	}
}