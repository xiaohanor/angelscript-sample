
enum EDebugViewMode
{
	None,
	Normal,
	Unlit,
	Wireframe,
	Unshadowed,
};


class UDebugViewModeManager
{
	EDebugViewMode CurrentMode = EDebugViewMode::None;
	bool bDebugViewActive = false;

	TArray<FInstigator> DebugDisableAntiAliasingInstigators;

	void ActivateDebugViewMode()
	{
		if (bDebugViewActive)
			return;

		bDebugViewActive = true;
		SetDebugViewMode(CurrentMode);
	}

	void DeactivateDebugViewMode()
	{
		if (!bDebugViewActive)
			return;
		bDebugViewActive = false;

		if (CurrentMode != EDebugViewMode::None)
		{
			Console::ExecuteConsoleCommand("ShowFlag.Lighting 2");
			Console::ExecuteConsoleCommand("ShowFlag.Wireframe 2");
			Console::ExecuteConsoleCommand("ShowFlag.DynamicShadows 2");
			Console::ExecuteConsoleCommand("Haze.GameSkyShadowCascadeQuality 2");
		}
	}

	void SetDebugViewMode(EDebugViewMode ViewMode)
	{
		CurrentMode = ViewMode;
		switch (CurrentMode)
		{
			case EDebugViewMode::Normal:
				Console::ExecuteConsoleCommand("ShowFlag.Lighting 2");
				Console::ExecuteConsoleCommand("ShowFlag.Wireframe 2");
				Console::ExecuteConsoleCommand("ShowFlag.DynamicShadows 2");
				Console::ExecuteConsoleCommand("Haze.GameSkyShadowCascadeQuality 2");
			break;
			case EDebugViewMode::Unlit:
				Console::ExecuteConsoleCommand("ShowFlag.Lighting 0");
				Console::ExecuteConsoleCommand("ShowFlag.Wireframe 0");
				Console::ExecuteConsoleCommand("ShowFlag.DynamicShadows 0");
				Console::ExecuteConsoleCommand("Haze.GameSkyShadowCascadeQuality 0");
			break;
			case EDebugViewMode::Wireframe:
				Console::ExecuteConsoleCommand("ShowFlag.Lighting 1");
				Console::ExecuteConsoleCommand("ShowFlag.Wireframe 1");
				Console::ExecuteConsoleCommand("ShowFlag.DynamicShadows 0");
				Console::ExecuteConsoleCommand("Haze.GameSkyShadowCascadeQuality 0");
			break;
			case EDebugViewMode::Unshadowed:
				Console::ExecuteConsoleCommand("ShowFlag.Lighting 1");
				Console::ExecuteConsoleCommand("ShowFlag.Wireframe 0");
				Console::ExecuteConsoleCommand("ShowFlag.DynamicShadows 0");
				Console::ExecuteConsoleCommand("Haze.GameSkyShadowCascadeQuality 0");
			break;
			case EDebugViewMode::None:
			break;
		}
	}

	void SetDebugDisableAntiAliasing(FInstigator Instigator, bool bDisableAntiAliasing)
	{
		if (bDisableAntiAliasing)
			DebugDisableAntiAliasingInstigators.AddUnique(Instigator);
		else
			DebugDisableAntiAliasingInstigators.Remove(Instigator);

		if (DebugDisableAntiAliasingInstigators.Num() != 0)
			Console::ExecuteConsoleCommand("ShowFlag.AntiAliasing 0");
		else
			Console::ExecuteConsoleCommand("ShowFlag.AntiAliasing 2");
	}
};

class UDebugViewModeNormalDevInput : UHazeDevInputHandler
{
	default Name = n"View Mode: Normal";
	default Category = n"View";
	default bTriggerLocalOnly = true;

	default AddGlobalKey(EKeys::F1);
	default AddKey(EKeys::F1);
	default AddKey(EKeys::Gamepad_FaceButton_Bottom);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		auto Manager = Cast<UDebugViewModeManager>(UDebugViewModeManager.DefaultObject);
		Manager.ActivateDebugViewMode();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		auto Manager = Cast<UDebugViewModeManager>(UDebugViewModeManager.DefaultObject);
		Manager.DeactivateDebugViewMode();
	}

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		auto Manager = Cast<UDebugViewModeManager>(UDebugViewModeManager.DefaultObject);
		Manager.SetDebugViewMode(EDebugViewMode::Normal);
	}
}

class UDebugViewModeWireframeDevInput : UHazeDevInputHandler
{
	default Name = n"View Mode: Wireframe";
	default Category = n"View";
	default bTriggerLocalOnly = true;

	default AddGlobalKey(EKeys::F2);
	default AddKey(EKeys::F2);
	default AddKey(EKeys::Gamepad_FaceButton_Right);

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		auto Manager = Cast<UDebugViewModeManager>(UDebugViewModeManager.DefaultObject);
		Manager.SetDebugViewMode(EDebugViewMode::Wireframe);
	}
}

class UDebugViewModeUnlitDevInput : UHazeDevInputHandler
{
	default Name = n"View Mode: Unlit";
	default Category = n"View";
	default bTriggerLocalOnly = true;

	default AddGlobalKey(EKeys::F3);
	default AddKey(EKeys::F3);
	default AddKey(EKeys::Gamepad_FaceButton_Top);

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		auto Manager = Cast<UDebugViewModeManager>(UDebugViewModeManager.DefaultObject);
		Manager.SetDebugViewMode(EDebugViewMode::Unlit);
	}
}

class UDebugViewModeUnshadowedDevInput : UHazeDevInputHandler
{
	default Name = n"View Mode: Unshadowed";
	default Category = n"View";
	default bTriggerLocalOnly = true;

	default AddGlobalKey(EKeys::F4);
	default AddKey(EKeys::F4);
	default AddKey(EKeys::Gamepad_FaceButton_Left);

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		auto Manager = Cast<UDebugViewModeManager>(UDebugViewModeManager.DefaultObject);
		Manager.SetDebugViewMode(EDebugViewMode::Unshadowed);
	}
}

class UDebugViewModeCameraLightDevInput : UHazeDevInputHandler
{
	default Name = n"Toggle Camera Light";
	default Category = n"View";
	default bTriggerLocalOnly = true;

	default AddGlobalKey(EKeys::F6);
	default AddKey(EKeys::F6);
	default AddKey(EKeys::Gamepad_RightShoulder);

	UFUNCTION(BlueprintOverride)
	bool CanBeTriggered()
	{
#if EDITOR
		return true;
#else
		return false;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		Console::ExecuteConsoleCommand("Haze.Camera.Light.Toggle");
	}
}