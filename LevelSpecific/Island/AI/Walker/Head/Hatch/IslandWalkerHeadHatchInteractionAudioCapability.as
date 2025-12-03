class UIslandWalkerHeadHatchInteractionAudioCapability : UHazeCapability
{
	UIslandWalkerHeadHatchInteractionComponent InteractionComp;

	default CapabilityTags.Add(Audio::Tags::LevelSpecificListener);
	default CapabilityTags.Add(Audio::Tags::ProxyListenerBlocker);
	default TickGroup = Audio::ListenerTickGroup;

	FHazeAcceleratedVector AccListenerVector;

	float DelayedActivationTimer = 1.0;
	AIslandWalkerHead Head;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Head = Cast<AIslandWalkerHead>(Owner);
		InteractionComp = UIslandWalkerHeadHatchInteractionComponent::Get(Head);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(InteractionComp.State == EWalkerHeadHatchInteractionState::Open
		|| InteractionComp.State == EWalkerHeadHatchInteractionState::LiftOff)
			return true;

		// if(Head.HeadComp.bAtEndOfEscape)
		// 	return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block the default listener
		for(auto Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(Audio::Tags::DefaultListener, this);
		}

		DelayedActivationTimer = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DelayedActivationTimer > 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Unblock the default listener
		for(auto Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(Audio::Tags::DefaultListener, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		for(auto Player : Game::GetPlayers())
		{
			Player.PlayerListener.SetWorldTransform(Player.GetViewTransform());
		}

		if(Head.HeadComp.bHeadEscapeSuccess)
		{
			DelayedActivationTimer = 0.0;
		}
		else if(InteractionComp.State == EWalkerHeadHatchInteractionState::None)
		{
			DelayedActivationTimer -= DeltaTime;
		}
	}
}