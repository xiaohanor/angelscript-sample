class UPlayerSidescrollerListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::Sidescroller);
	default TickGroup = Audio::ListenerTickGroup;

	private UHazeAudioListenerComponent Listener;
	private UHazeAudioPlayerComponent AudioComponent;
	private UHazeAudioEmitter DefaultEmitter;
	private UCameraUserComponent User;
	private AHazePlayerCharacter OtherPlayer;
	private UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	private FVector2D PreviousScreenPosition;
	private bool bSetListenerPosition = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OtherPlayer = Player.GetOtherPlayer();
		Listener = UHazeAudioListenerComponent::Get(Player);
		DefaultEmitter = Player.PlayerAudioComponent.AnyEmitter;
		User = UCameraUserComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PerspectiveModeComp.PerspectiveMode != EPlayerMovementPerspectiveMode::SideScroller)
			return false;

		if(SceneView::IsFullScreen() || SceneView::IsPendingFullscreen())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PerspectiveModeComp.PerspectiveMode != EPlayerMovementPerspectiveMode::SideScroller)
			return true;

		return false;
	}

	private bool HasProxyListenerPositioningOverride() const
	{
		if(Player.IsAnyCapabilityActive(Audio::Tags::SidescrollerProxyEmitter))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// If it's already blocked due to level specific listeners don't set the position.
		bSetListenerPosition = Player.IsAnyCapabilityActive(Audio::Tags::LevelSpecificListener) == false;

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
		if (bSetListenerPosition && (HasProxyListenerPositioningOverride() == false))
		{
			auto Transform = Player.GetViewTransform();
			Listener.SetWorldTransform(Transform);
		}

		Audio::SetSidescrollerScreenPositionRelativePanning(Player, OtherPlayer, PreviousScreenPosition);

#if TEST
		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			if (bSetListenerPosition)
				Audio::DebugListenerLocations(Player);
			PrintToScreen("PlayerPanning: "+ Player.PlayerAudioComponent.Panning);
			PrintToScreen("bSetListenerPosition: "+ (bSetListenerPosition && DefaultEmitter.HasProxy() == false));
		}
#endif
	}
}