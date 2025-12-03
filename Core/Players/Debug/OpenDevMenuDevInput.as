class UOpenDevMenuDevInput : UHazeDevInputHandler
{
	default Name = n"Open Dev Menu";
	default Category = n"Default";
	default bTriggerLocalOnly = true;

	default AddKey(EKeys::Gamepad_Special_Right);
	default AddKey(EKeys::Tab);

	default DisplaySortOrder = 1000;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		DevMenu::OpenDevMenuOverlay();
	}
}