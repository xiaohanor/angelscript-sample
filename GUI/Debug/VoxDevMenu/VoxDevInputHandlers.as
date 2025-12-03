
class UVoxDevTimelineToggleInputHandler : UHazeDevInputHandler
{
	default SetName(n"Toggle Vox Viewport Timeline");
	default SetCategory(n"Settings");
	default AddKey(FKey(n"t"));
	default AddKey(EKeys::Gamepad_DPad_Up);

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		bool bEnabled = VoxCVar::HazeVoxShowViewportTimeline.GetInt() != 0;
		Console::SetConsoleVariableInt("HazeVox.ShowViewportTimeline", !bEnabled ? 1 : 0, bOverrideValueSetByConsole = true);
	}
}
