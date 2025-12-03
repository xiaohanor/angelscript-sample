class UJetskiUnderwaterAudioCapability : UHazePlayerCapability
{
	private UJetskiDriverComponent JetskiDriverComp;
	private UJetskiDriverComponent OtherJetskiDriverComp;

	private float LastUnderwaterRTPCValue = -1.0;
	const FHazeAudioID UnderwaterRTPC = FHazeAudioID("Rtpc_Shared_Camera_InWater");

	bool IsJetskiUnderwater(UJetskiDriverComponent JetskiDriver) const
	{
		return JetskiDriver.Jetski.IsUnderwater() || JetskiDriver.Jetski.GetMovementState() == EJetskiMovementState::Underwater;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetskiDriverComp = UJetskiDriverComponent::Get(Player);
		OtherJetskiDriverComp = UJetskiDriverComponent::Get(Player.OtherPlayer);
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
		LastUnderwaterRTPCValue = -1.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(OtherJetskiDriverComp == nullptr)
			OtherJetskiDriverComp = UJetskiDriverComponent::Get(Player.OtherPlayer);
			if(OtherJetskiDriverComp == nullptr)
				return;

		float WaterRTPCValue = -1;
		const bool bPlayerJetskiUnderwater = IsJetskiUnderwater(JetskiDriverComp);
		const bool bOtherPlayerJetskiUnderwater = IsJetskiUnderwater(OtherJetskiDriverComp);

		if(!bPlayerJetskiUnderwater && !bOtherPlayerJetskiUnderwater)
			WaterRTPCValue = 0.0;
		else if(bPlayerJetskiUnderwater && bOtherPlayerJetskiUnderwater)
			WaterRTPCValue = 2.0;
		else if(bPlayerJetskiUnderwater || bOtherPlayerJetskiUnderwater)
			WaterRTPCValue = 1.0;

		if(WaterRTPCValue != LastUnderwaterRTPCValue)
			AudioComponent::SetGlobalRTPC(UnderwaterRTPC, WaterRTPCValue, 300);

		//PrintToScreenScaled(""+WaterRTPCValue);

		LastUnderwaterRTPCValue = WaterRTPCValue;

	}

}