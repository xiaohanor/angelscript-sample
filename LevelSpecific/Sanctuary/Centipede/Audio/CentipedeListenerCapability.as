class UCentipedeListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::ProxyListenerBlocker);

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
	void TickActive(float DeltaTime)
	{
		FTransform ListenerTransform = Player.GetViewTransform();
		ListenerTransform.SetLocation(Audio::GetEarsLocation(Player));

		Player.PlayerListener.SetWorldTransform(ListenerTransform);		
	}
}
