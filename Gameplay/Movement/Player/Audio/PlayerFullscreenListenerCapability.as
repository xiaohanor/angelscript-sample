

class UPlayerFullscreenListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::Fullscreen);
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
		return !Player.bIsParticipatingInCutscene && SceneView::IsFullScreen();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Player.bIsParticipatingInCutscene || !SceneView::IsFullScreen();
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
		if (bSetListenerPosition && DefaultEmitter.HasProxy() == false)
		{
			auto ViewTransform = Player.GetViewTransform();
			// Side scroller - Everything on camera
			// MovingTowardsCamera - Camera rotation, Camera location plus a distance
			// TopDown - Camera panning, listeners on players
			// ThirdPerson - Camera panning, listeners on players
			FTransform Transform;
			switch(PerspectiveModeComp.GetPerspectiveMode())
			{
				case EPlayerMovementPerspectiveMode::SideScroller:
				Transform = Player.GetViewTransform();
				break;
				case EPlayerMovementPerspectiveMode::MovingTowardsCamera:
				case EPlayerMovementPerspectiveMode::ThirdPerson:
				{
					Transform = Player.GetViewTransform();
					const float MaxDistance = 20;
					Transform.SetLocation(GetPositionBetweenCameraAndPlayer(Transform, MaxDistance));
				}
				break;
				case EPlayerMovementPerspectiveMode::TopDown:
				Transform = Player.GetViewTransform();
				Transform.SetLocation(Audio::GetEarsLocation(Player));
				break;
			}

			Listener.SetWorldTransform(Transform);
		}

		Audio::SetScreenPositionRelativePanning(Player, OtherPlayer, PreviousScreenPosition);
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

	private FVector GetPositionBetweenCameraAndPlayer(
		const FTransform& View,
		const float& MaxDistance)
	{
		FVector EarsLocation = Audio::GetEarsLocation(Player);
		FVector PlayerDirection = (EarsLocation-View.Location);

		float ActorScale = Player.GetActorScale3D().Y;
		const float HalfDistanceFromCamera = PlayerDirection.Size() * 0.5;
		auto Distance = Math::Clamp(HalfDistanceFromCamera, SMALL_NUMBER, MaxDistance * ActorScale);

		PlayerDirection.Normalize();

		return View.Location + PlayerDirection * Distance;
	}
}