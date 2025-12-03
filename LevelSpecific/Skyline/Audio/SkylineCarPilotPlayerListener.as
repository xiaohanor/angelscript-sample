class USkylineCarPilotPlayerListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::Skyline::CarListener);
	default CapabilityTags.Add(Audio::Tags::LevelSpecificListener);
	default TickGroup = Audio::ListenerTickGroup;

	UCameraUserComponent User;
	UCameraUserComponent OtherCameraUser;
	UHazeAudioListenerComponent Listener;
	UHazeAudioReflectionComponent ReflectionComponent;

	USkylineFlyingCarGunnerComponent CarGunnerComponent;
	USkylineFlyingCarPilotComponent PilotComponent;

	private FVector2D PreviousScreenPosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Player);
		OtherCameraUser = UCameraUserComponent::Get(Player.GetOtherPlayer());
		Listener = Player.PlayerListener;
		ReflectionComponent = UHazeAudioReflectionComponent::Get(Player);

		PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PilotComponent.Car == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PilotComponent.Car == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// We want the gunnarcomponent regardless of which player it is.
		if (CarGunnerComponent == nullptr)
			CarGunnerComponent = USkylineFlyingCarGunnerComponent::Get(Player.OtherPlayer);

		// Block the default listener
		Player.BlockCapabilities(Audio::Tags::DefaultListener, this);
		ReflectionComponent.AddActorToIgnore(CarGunnerComponent.Car);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::DefaultListener, this);
		ReflectionComponent.RemoveActorToIgnore(CarGunnerComponent.Car);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!SceneView::IsFullScreen() && SceneView::SplitScreenMode == EHazeSplitScreenMode::Vertical)
			Audio::SetPanningBasedOnScreenPercentage(Player);
		else
			Audio::SetScreenPositionRelativePanning(Player, Player.OtherPlayer, PreviousScreenPosition);

		// Will keep the listener in a sphere around the dragon blocked by geo, based on camera
		auto ViewTransform = Player.ViewTransform;
		FVector CarGunLocation = CarGunnerComponent.Car.GunPivot.GetWorldLocation();
		ViewTransform.SetLocation(CarGunLocation);

		Listener.SetWorldTransform(ViewTransform);

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Audio::DebugListenerLocations(Player);
			PrintToScreen("PlayerPanning: "+ Player.PlayerAudioComponent.Panning);
		}
	}
}