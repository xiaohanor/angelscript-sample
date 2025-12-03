class UNetworkViewModeNormalDevInput : UHazeDevInputHandler
{
	default Name = n"Network View: Normal";
	default Category = n"Network";
	default bTriggerLocalOnly = true;

	default AddKey(EKeys::F1);
	default AddKey(EKeys::Gamepad_FaceButton_Bottom);

	UFUNCTION(BlueprintOverride)
	bool CanBeTriggered()
	{
#if EDITOR
		if (Editor::EditorPlayModeIsNetSingleScreen)
			return true;
#endif
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		Console::SetConsoleVariableInt("Haze.SingleScreenNetworkViewMode", 0);

		auto DevInput = UHazeDevInputComponent::Get(PlayerOwner);
		DevInput.SetCurrentCategoryIndex(0);
		DevInput.CloseAndFlushInput();
	}
}

class UNetworkViewModeMioDevInput : UHazeDevInputHandler
{
	default Name = n"Network View: Mio";
	default Category = n"Network";
	default bTriggerLocalOnly = true;

	default AddKey(EKeys::F2);
	default AddKey(EKeys::Gamepad_LeftShoulder);

	UFUNCTION(BlueprintOverride)
	bool CanBeTriggered()
	{
#if EDITOR
		if (Editor::EditorPlayModeIsNetSingleScreen)
			return true;
#endif
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		if (Network::HasWorldControl() == Game::Mio.HasControl())
			Console::SetConsoleVariableInt("Haze.SingleScreenNetworkViewMode", 4);
		else
			Console::SetConsoleVariableInt("Haze.SingleScreenNetworkViewMode", 5);

		auto DevInput = UHazeDevInputComponent::Get(PlayerOwner);
		DevInput.SetCurrentCategoryIndex(0);
		DevInput.CloseAndFlushInput();
	}
}

class UNetworkViewModeZoeDevInput : UHazeDevInputHandler
{
	default Name = n"Network View: Zoe";
	default Category = n"Network";
	default bTriggerLocalOnly = true;

	default AddKey(EKeys::F3);
	default AddKey(EKeys::Gamepad_RightShoulder);

	UFUNCTION(BlueprintOverride)
	bool CanBeTriggered()
	{
#if EDITOR
		if (Editor::EditorPlayModeIsNetSingleScreen)
			return true;
#endif
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		if (Network::HasWorldControl() == Game::Mio.HasControl())
			Console::SetConsoleVariableInt("Haze.SingleScreenNetworkViewMode", 5);
		else
			Console::SetConsoleVariableInt("Haze.SingleScreenNetworkViewMode", 4);

		auto DevInput = UHazeDevInputComponent::Get(PlayerOwner);
		DevInput.SetCurrentCategoryIndex(0);
		DevInput.CloseAndFlushInput();
	}
}