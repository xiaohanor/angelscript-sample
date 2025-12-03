class UPlayerAudioDebugNetworkCapability : UHazePlayerCapability
{
	const FString ConsoleName = "DisableAudioOutputs";
	const FConsoleVariable ConsoleVar(ConsoleName, 0, "Mutes audio posted by either Remote|Control|None side");

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return UHazeAudioNetworkDebugManager::IsNetworkSimulating() && Player.IsMio();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !UHazeAudioNetworkDebugManager::IsNetworkSimulating();
	}

	int PreviousDebugValue = -1;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		int NewValue = ConsoleVar.GetInt();

		EDebugAudioOutputBlock Output = EDebugAudioOutputBlock(NewValue);
		if (NewValue != PreviousDebugValue)
		{
			auto Manager = UHazeAudioNetworkDebugManager::Get(this);

			// bool bMute =
			// 	Output == EDebugAudioOutputBlock::Local && HasControl() ||
			// 	Output == EDebugAudioOutputBlock::Remote && !HasControl();

			Manager.SetNetworkAudioOutput(Output == EDebugAudioOutputBlock::Control, Output == EDebugAudioOutputBlock::Remote);
		}

		PreviousDebugValue = NewValue;
	}
}