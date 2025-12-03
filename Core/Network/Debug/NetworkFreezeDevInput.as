class UNetworkFreezeDevInput : UHazeDevInputHandler
{
	default Name = n"Freeze Network";
	default Category = n"Network";
	default bTriggerLocalOnly = true;

	default AddKey(EKeys::Gamepad_FaceButton_Top);
	default AddKey(EKeys::X);

	UFUNCTION(BlueprintOverride)
	bool CanBeTriggered()
	{
#if EDITOR
		if (Network::IsGameNetworked())
			return true;
#endif
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Trigger()
	{
		Network::DebugToggleFrozen();
	}
}