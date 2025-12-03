class UPlayerMagneticDroneListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::Prison::DroneListener);
	default CapabilityTags.Add(Audio::Tags::LevelSpecificListener);
	
	default TickGroup = Audio::ListenerTickGroup;
	
	UMagnetDroneComponent DroneComp;

	UCameraUserComponent User;
	UHazeAudioListenerComponent Listener;

	private float HeightOffset = 100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		User = UCameraUserComponent::Get(Player);

		Listener = Player.PlayerListener;
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
		// Block the default listener
		Player.BlockCapabilities(Audio::Tags::DefaultListener, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::DefaultListener, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!SceneView::IsFullScreen())
			Audio::SetPanningBasedOnScreenPercentage(Player);

		auto ActorTransform = Player.ActorTransform;
		auto Forward = Player.ViewRotation.ForwardVector;
		Forward.Z = 0;

		ActorTransform.SetRotation(Forward.Rotation());
		ActorTransform.SetLocation(ActorTransform.GetLocation() + FVector(0,0, HeightOffset));

		Listener.SetWorldTransform(ActorTransform);

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Audio::DebugListenerLocations(Player);
		}
	}
}