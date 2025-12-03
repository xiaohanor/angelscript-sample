class UPlayerRemoteHackingListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	// default CapabilityTags.Add(Audio::Tags::LevelSpecificListener);
	default CapabilityTags.Add(Audio::Tags::ProxyListenerBlocker);
	default TickGroup = Audio::ListenerTickGroup;
	
	UPlayerTargetablesComponent TargetablesComponent;
	URemoteHackingPlayerComponent HackPlayerComp;

	UCameraUserComponent User;
	UCameraUserComponent OtherCameraUser;
	UHazeAudioListenerComponent Listener;

	UHazeAudioReflectionComponent ReflectionComponent;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	AActor HackedActor = nullptr;
	FVector2D PreviousScreenPosition;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		HackPlayerComp = URemoteHackingPlayerComponent::Get(Player);
		User = UCameraUserComponent::Get(Player);
		OtherCameraUser = UCameraUserComponent::Get(Player.GetOtherPlayer());
		ReflectionComponent = UHazeAudioReflectionComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);

		Listener = Player.PlayerListener;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return !User.IsCameraAttachedToPlayer() && HackPlayerComp.bHackActive;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return User.IsCameraAttachedToPlayer() || !HackPlayerComp.bHackActive;
	}

	private AActor GetHackTargetActor()
	{
		return HackPlayerComp.CurrentHackingResponseComp.GetOwner();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block the default listener
		Player.BlockCapabilities(Audio::Tags::DefaultListener, this);
		Player.BlockCapabilities(Audio::Tags::Sidescroller, this);
		Player.BlockCapabilities(Audio::Tags::Fullscreen, this);
		HackedActor = GetHackTargetActor();

		ReflectionComponent.AddActorToIgnore(HackedActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::DefaultListener, this);
		Player.UnblockCapabilities(Audio::Tags::Sidescroller, this);
		Player.UnblockCapabilities(Audio::Tags::Fullscreen, this);

		ReflectionComponent.RemoveActorToIgnore(HackedActor);
		HackedActor = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// NOTE: When the original implementation was implemented some behavior (IsControlledByInput/CanControlCamera) was very different.

		// Default when hacking and can control camera
		// Add exception when controlling a actor (robot mouse) that's really close to the camera, BUT is marked as uncontrollable eventually.
		if (User.IsControlledByInput() || (HackedActor != nullptr && HackedActor.ActorLocation.DistSquared(Player.ViewLocation) < 2000 * 2000))
		{
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
					if (Cast<ARemoteHackableSmokeRobot>(HackedActor) != nullptr)
					{
						Transform.SetLocation(HackedActor.ActorLocation);
					}
					else
					{
						const float MaxDistance = 20;
						Transform.SetLocation(GetPositionBetweenCameraAndPlayer(Transform, MaxDistance));
					}
				}
				break;
				case EPlayerMovementPerspectiveMode::TopDown:
				Transform = Player.GetViewTransform();
				Transform.SetLocation(Audio::GetEarsLocation(Player));
				break;
			}

			Listener.SetWorldTransform(Transform);
		}
		else
		{
			if (!User.IsCameraAttachedToPlayer() && !User.CanControlCamera())
			{
				// Follow the other player at cellblock <- no longer valid.
				if (OtherCameraUser.CanControlCamera())
				{
					auto OtherPlayer = Player.GetOtherPlayer();
					Listener.SetWorldTransform(OtherPlayer.PlayerListener.WorldTransform);
				}
				// Side scroller
				else 
				{
					auto ActorTransform = Player.ActorTransform;
					Listener.SetWorldTransform(ActorTransform);
				}
			}
			else
			{
				// Follow the camera, for instance at cellblock when transitioning to top camera.
				Listener.SetWorldTransform(Player.ViewTransform);
			}
		}

		if (!SceneView::IsFullScreen())
			Audio::SetPanningBasedOnScreenPercentage(Player);
		else
			Audio::SetScreenPositionRelativePanning(Player, Player.OtherPlayer, PreviousScreenPosition);

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Audio::DebugListenerLocations(Player);
			PrintToScreen("PlayerPanning: "+ Player.PlayerAudioComponent.Panning);
		}
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