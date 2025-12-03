class UDebugTogglePauseDuringDevInput : UHazeDevInputHandler
{
	default Name = n"Auto-Pause During DevInput";
	default Category = n"Settings";
	default bTriggerLocalOnly = true;

	default DisplaySortOrder = 1000;

	default AddKey(EKeys::Gamepad_DPad_Right);
	default AddKey(EKeys::P);

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		auto Config = UDevInputConfig::Get();
		Config.bPauseDuringDevInput = !Config.bPauseDuringDevInput;
		Config.SaveConfig();
	}

	UFUNCTION(BlueprintOverride)
	void GetStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if (UDevInputConfig::Get().bPauseDuringDevInput)
		{
			OutDescription = "[ Pause: ON ]";
			OutColor = FLinearColor::Green;
		}
		else
		{
			OutDescription = "[ Pause: OFF ]";
			OutColor = FLinearColor::Red;
		}
	}
}