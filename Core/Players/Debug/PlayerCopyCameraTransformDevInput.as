class UPlayerCopyMioCameraTransformDevInput : UHazeDevInputHandler
{
	default Name = n"Copy Mio Camera Transform to Clipboard";
	default Category = n"View";
	default AddKey(EKeys::J);
	default AddGlobalInputChord(FInputChord(EKeys::J, false, false, true, false));

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		FTransform CameraTransform = Game::Mio.ViewTransform;
		Editor::CopyToClipBoard(CameraTransform.ToString());

		PrintScaled(f"Copied Mio Camera Transform to Clipboard");
	}
}

class UPlayerCopyZoeCameraTransformDevInput : UHazeDevInputHandler
{
	default Name = n"Copy Zoe Camera Transform to Clipboard";
	default Category = n"View";
	default AddKey(EKeys::K);
	default AddGlobalInputChord(FInputChord(EKeys::K, false, false, true, false));

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		FTransform CameraTransform = Game::Zoe.ViewTransform;
		Editor::CopyToClipBoard(CameraTransform.ToString());

		PrintScaled(f"Copied Zoe Camera Transform to Clipboard");
	}
}