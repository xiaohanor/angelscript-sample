
class UPlayerDebugCameraListenerCapability : UHazePlayerCapability
{
	default TickGroup = Audio::ListenerTickGroup;

	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"Audio");
    default DebugCategory = n"Audio";

	UHazeAudioListenerComponent Listener;
	UHazeAudioComponent AudioComponent;
	UHazeAudioReverbComponent ReverbComponent;

	FVector PreviousReverbPosition;
	FVector PreviousAudioPosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Listener = Player.PlayerListener;
		AudioComponent = Player.PlayerAudioComponent;
		ReverbComponent = AudioComponent.GetReverbComponent();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Player.IsAnyCapabilityActive(CameraTags::CameraDebugCamera);
	}
 
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !Player.IsAnyCapabilityActive(CameraTags::CameraDebugCamera);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousAudioPosition = AudioComponent.GetRelativeLocation();
		PreviousReverbPosition = ReverbComponent.GetRelativeLocation();

		Player.BlockCapabilities(Audio::Tags::Listener, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AudioComponent.SetRelativeLocation(PreviousAudioPosition);
		ReverbComponent.SetRelativeLocation(PreviousReverbPosition);

		Player.UnblockCapabilities(Audio::Tags::Listener, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Listener.SetWorldTransform(Player.GetViewTransform());
		//AudioComponent.SetWorldLocation(Listener.GetWorldLocation());
		//ReverbComponent.SetWorldLocation(Listener.GetWorldLocation());

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Debug::DrawDebugPoint(Listener.GetWorldLocation(), 20.0, FLinearColor::Red);
		}
	}
}