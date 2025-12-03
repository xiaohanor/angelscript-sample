#if EDITOR

// ↓ This is an example file, so we ifdef out the whole file so the example menu options don't show up everywhere
#ifdef false

/**
 * Example editor subsystem that adds buttons to the screen and adds input bindings.
 */
class UExampleEditorSubsystemInput : UHazeEditorSubsystem
{
	bool bIsRelevant = false;

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsChanged()
	{
		// Only activate this subsystem in levels that have this actor type in them
		bIsRelevant = TListedActors<APropLine>().Num() != 0;
	}

	UFUNCTION(BlueprintOverride)
	bool OnLevelEditorKeyInput(FKey Key, EInputEvent Event)
	{
		if (!bIsRelevant)
			return false;

		// Intercept the X key when pressed on the level viewport
		if (Key == EKeys::X)
		{
			if (Event == EInputEvent::IE_Pressed)
				Print("Test");
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool OnLevelEditorClick(FKey Key, EInputEvent Event, UObject ClickedObject)
	{
		if (!bIsRelevant)
			return false;

		UPrimitiveComponent ClickedComponent = Cast<UPrimitiveComponent>(ClickedObject);
		if (ClickedComponent != nullptr)
		{
			// Intercept clicks to primitive components and make them move upward
			ClickedComponent.RelativeLocation += FVector(0, 0, 100);
			Print(f"Clicked {ClickedComponent}");
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bIsRelevant)
			return;

		// We can draw on the overlay to the level editor viewport for custom tooling
		auto Overlay = GetEditorViewportOverlay();
		if (!Overlay.IsVisible())
			return;

		auto Canvas = Overlay.BeginCanvasPanel();
		auto ButtonBar = Canvas
			.SlotAnchors(0.5, 0.0)
			.SlotAlignment(0.5, 0.0)
			.SlotAutoSize(true)
			.HorizontalBox()
		;

		auto TestButton = ButtonBar
			.Button("♥ Test Button")
			.Padding(6)
		;
		if (TestButton.WasClicked())
		{
			Print("Button clicked!");
		}
	}
}

#endif

#endif