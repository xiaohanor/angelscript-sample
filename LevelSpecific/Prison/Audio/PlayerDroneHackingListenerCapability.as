class UPlayerDroneHackingListenerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::Prison::DroneListener);
	default CapabilityTags.Add(Audio::Tags::LevelSpecificListener);
	default TickGroup = Audio::ListenerTickGroup;
	
	UPlayerTargetablesComponent TargetablesComponent;
	UPlayerSwarmDroneHijackComponent SwarmDroneHijackComp;

	UCameraUserComponent User;
	UCameraUserComponent OtherCameraUser;
	UHazeAudioListenerComponent Listener;

	UHazeAudioReflectionComponent ReflectionComponent;

	private FVector2D PreviousScreenPosition;
	private bool bIsInDroneForm = false;
	private AActor HackedActor = nullptr;
	private AActor ListenerTargetActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		SwarmDroneHijackComp = UPlayerSwarmDroneHijackComponent::Get(Player);
		User = UCameraUserComponent::Get(Player);
		OtherCameraUser = UCameraUserComponent::Get(Player.GetOtherPlayer());
		ReflectionComponent = UHazeAudioReflectionComponent::Get(Player);

		Listener = Player.PlayerListener;

		bIsInDroneForm = SwarmDroneHijackComp != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return SwarmDroneHijackComp.IsHijackActive();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !SwarmDroneHijackComp.IsHijackActive();
	}

	private AActor GetHackTargetActor()
	{
		auto Target = TargetablesComponent.GetPrimaryTargetForCategory(SwarmDroneTags::SwarmDroneHijackTargetableCategory);
		if (Target != nullptr)
			return Target.GetOwner();
		
		return Player;
	}

	private AActor GetTargetActor()
	{
		auto Target = TargetablesComponent.GetPrimaryTargetForCategory(SwarmDroneTags::SwarmDroneHijackTargetableCategory);
		if (Target != nullptr)
			return Target.GetOwner();

		return Player;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block the default listener
		Player.BlockCapabilities(Audio::Tags::DefaultListener, this);
		Player.BlockCapabilities(Audio::Tags::Fullscreen, this);

		HackedActor = GetHackTargetActor();
		ListenerTargetActor = GetTargetActor();

		ReflectionComponent.AddActorToIgnore(HackedActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Audio::Tags::DefaultListener, this);
		Player.UnblockCapabilities(Audio::Tags::Fullscreen, this);

		ReflectionComponent.RemoveActorToIgnore(HackedActor);
		HackedActor = nullptr;
		ListenerTargetActor = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!SceneView::IsFullScreen() && SceneView::SplitScreenMode == EHazeSplitScreenMode::Vertical)
			Audio::SetPanningBasedOnScreenPercentage(Player);
		else 
			Audio::SetScreenPositionRelativePanning(Player, Player.OtherPlayer, PreviousScreenPosition);
		
		// When in pinball section use the other listeners position
		if (SceneView::IsFullScreen() && !SceneView::IsInView(Player, ListenerTargetActor.ActorLocation))
		{
			Listener.SetWorldTransform(Player.OtherPlayer.PlayerListener.WorldTransform);
		}
		else 
		{
			auto ActorTransform = ListenerTargetActor.ActorTransform;
			ActorTransform.SetRotation(Player.ViewRotation);
			Listener.SetWorldTransform(ActorTransform);
		}

		if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
		{
			Audio::DebugListenerLocations(Player);
			PrintToScreen("PlayerPanning: "+ Player.PlayerAudioComponent.Panning);
		}
	}
}