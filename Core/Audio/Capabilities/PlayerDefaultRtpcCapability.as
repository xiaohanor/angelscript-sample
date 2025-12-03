class UPlayerDefaultRtpcCapability : UHazePlayerCapability
{
	bool bHasActivated = false;
	const FHazeAudioID Rtpc_Shared_Player_IsMio_IsZoe = FHazeAudioID("Rtpc_Shared_Player_IsMio_IsZoe");

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bHasActivated)
			return false;

		if(Player == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Player-character RTPC
		const float PlayerCharacterValue = Player.IsMio() ? -1.0 : 1.0;
		Player.PlayerAudioComponent.SetRTPCOnEmitters(Rtpc_Shared_Player_IsMio_IsZoe, PlayerCharacterValue, 0);

		bHasActivated = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Right now we are only setting RTPCs on activation, this will need to be changed if we are to do stuff in TickActive
		return true;
	}
}