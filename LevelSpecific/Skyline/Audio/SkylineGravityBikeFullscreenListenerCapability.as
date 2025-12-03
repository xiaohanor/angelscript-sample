class USkylineGravityBikeFullscreenListenerCapability : UHazeCapability
{
	default CapabilityTags.Add(Audio::Tags::Listener);
	default CapabilityTags.Add(Audio::Tags::Skyline::GravityBikeListener);
	default CapabilityTags.Add(Audio::Tags::LevelSpecificListener);
	default TickGroup = Audio::ListenerTickGroup;

	TArray<AHazePlayerCharacter> Players;
	AGravityBikeSpline SplineBike;
	TArray<UAudioReflectionComponent> ReflectionComponents;
	TArray<UHazeMovementComponent> MovementComponents;	

	private FVector2D PreviousScreenPosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineBike = Cast<AGravityBikeSpline>(Owner);
		Players = Game::GetPlayers();

		for(auto& Player : Players)
		{
			ReflectionComponents.Add(UAudioReflectionComponent::Get(Player));
			MovementComponents.Add(UHazeMovementComponent::Get(SplineBike));
		}
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
		for(int i = 0; i < Players.Num(); ++i)
		{
			Players[i].BlockCapabilities(Audio::Tags::DefaultListener, this);
			Players[i].BlockCapabilities(Audio::Tags::Fullscreen, this);
			
			ReflectionComponents[i].AddActorToIgnore(SplineBike);
			ReflectionComponents[i].SetMovementComponentOverride(MovementComponents[i]);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(int i = 0; i < Players.Num(); ++i)
		{
			Players[i].UnblockCapabilities(Audio::Tags::DefaultListener, this);
			Players[i].UnblockCapabilities(Audio::Tags::Fullscreen, this);

			ReflectionComponents[i].RemoveActorToIgnore(SplineBike);
			ReflectionComponents[i].ClearMovementComponentOverride();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto FullscreenPlayer = SceneView::GetFullScreenPlayer();
		if(FullscreenPlayer == nullptr)
		{
			// In this whole setting we want to use it as fullscreen all the way.
			FullscreenPlayer = Game::Mio;
		}

		Audio::SetScreenPositionRelativePanning(FullscreenPlayer, FullscreenPlayer.OtherPlayer, PreviousScreenPosition);

		for(auto& Player : Players)
		{	
			Player.PlayerListener.SetWorldTransform(FullscreenPlayer.ViewTransform);	

			if (IsDebugActive() || AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Players))
			{
				Audio::DebugListenerLocations(Player);
				PrintToScreen("PlayerPanning: "+ Player.PlayerAudioComponent.Panning);
			}
		}

		SplineBike.SplineBikePanningValue = FullscreenPlayer.PlayerAudioComponent.Panning;
	}
}