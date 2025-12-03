
class UWingSuitPlayerListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::WingSuitListener);

	UHazeAudioListenerComponent Listener;
	UCameraUserComponent User;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Listener = Player.PlayerListener;
		User = UCameraUserComponent::Get(Player);
		SetDefaultTransform();
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

	void SetDefaultTransform()
	{
		auto PlayerTransform = Player.GetViewTransform();
		PlayerTransform.SetLocation(Audio::GetEarsLocation(Player));
		Listener.SetWorldTransform(PlayerTransform);
	}

	UFUNCTION(BlueprintOverride)
	void OnStopQuiet()
	{
		SetDefaultTransform();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block the default listener
		Player.BlockCapabilities(Audio::Tags::Listener, this);

		SetDefaultTransform();
	}

	void UpdateListenerTransform(float DeltaTime)
	{
		Player.UnblockCapabilities(Audio::Tags::Listener, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SetDefaultTransform();

#if TEST
		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Debug::DrawDebugPoint(Listener.GetWorldLocation(), 20.0, FLinearColor::Red);
			Debug::DrawDebugDirectionArrow(Listener.GetWorldLocation(), Player.GetViewRotation().ForwardVector, 500, 25.0, LineColor = FLinearColor::DPink);
		
		}
#endif
	}
}