class UPlayerDragonTopDownListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Summit::TopDownDragonListener);
	default CapabilityTags.Add(Audio::Tags::ProxyListenerBlocker);

	default TickGroup = Audio::ListenerTickGroup;
	
	UCameraUserComponent User;
	UCameraUserComponent OtherCameraUser;
	UHazeAudioListenerComponent Listener;
	private FVector2D PreviousScreenPosition;
	private float DragonExtent = 1000;

	UPlayerTeenDragonComponent TeenDragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Player);
		OtherCameraUser = UCameraUserComponent::Get(Player.GetOtherPlayer());
		TeenDragonComp = UPlayerTeenDragonComponent::Get(Player);

		Listener = Player.PlayerListener;
		
		if (TeenDragonComp != nullptr)
			DragonExtent = TeenDragonComp.GetDragonMesh().BoundsRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return TeenDragonComp.bTopDownMode;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !TeenDragonComp.bTopDownMode;
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
		if (!SceneView::IsFullScreen() && SceneView::SplitScreenMode == EHazeSplitScreenMode::Vertical)
			Audio::SetPanningBasedOnScreenPercentage(Player);
		else 
			Audio::SetScreenPositionRelativePanning(Player, Player.OtherPlayer, PreviousScreenPosition);
		
		if (SceneView::IsFullScreen() && !SceneView::IsInView(Player, Player.ActorLocation))
		{
			Listener.SetWorldTransform(Player.OtherPlayer.PlayerListener.WorldTransform);
		}
		else 
		{
			// Will keep the listener in a sphere around the dragon blocked by geo, based on camera
			auto ViewTransform = Player.ViewTransform;

			auto PlayerLocation = Player.ActorLocation;
			auto PlayerDirection = PlayerLocation - ViewTransform.Location;
			PlayerDirection.Normalize();

			ViewTransform.SetLocation(PlayerLocation - (PlayerDirection * DragonExtent));
			Listener.SetWorldTransform(ViewTransform);
		}

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Audio::DebugListenerLocations(Player);
			PrintToScreen("PlayerPanning: "+ Player.PlayerAudioComponent.Panning);
		}
	}
}