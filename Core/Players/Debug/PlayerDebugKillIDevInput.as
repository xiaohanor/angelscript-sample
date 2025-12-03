class UPlayerDebugKillDevInput : UHazeDevInputHandler
{
	default Name = n"Kill Player";
	default Category = n"Default";

	default AddKey(EKeys::Gamepad_DPad_Down);
	default AddKey(EKeys::Y);

	default DisplaySortOrder = 1100;

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		PlayerOwner.KillPlayer();
	}
}