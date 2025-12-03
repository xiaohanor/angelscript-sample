class UPlayerSetPanningCapability: UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Audio;

	bool bHasActivated = false;
	const FHazeAudioID Rtpc_Panning = FHazeAudioID("Rtpc_SpeakerPanning_LR");

	float32 PreviousPanningValue = 0;
	UHazeAudioPlayerComponent AudioComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AudioComponent = Player.PlayerAudioComponent;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousPanningValue = AudioComponent.Panning;
		TriggerPanningUpdateOnAllPannedEmitters();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AudioComponent.Panning == PreviousPanningValue)
			return;
		PreviousPanningValue = AudioComponent.Panning;

		TriggerPanningUpdateOnAllPannedEmitters();
	}

	void TriggerPanningUpdateOnAllPannedEmitters()
	{
		// Notify component manager to update all emitters with the panning rtpc set.
		Audio::UpdatePlayerPanning();
	}
}