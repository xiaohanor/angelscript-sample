class APrisonIntroElevatorDoubleInteractionActor : ADoubleInteractionActor
{
	UPROPERTY(BlueprintReadWrite)
	AHazePlayerCharacter CurrentFirstPlayer;

	TPerPlayer<float> StartInteractionTimes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartInteractionTimes[0] = -1;
		StartInteractionTimes[1] = -1;
		
		if(Network::HasWorldControl())
		{
			OnPlayerStartedInteracting.AddUFunction(this, n"PlayerStartedInteracting");
			OnCancelBlendingIn.AddUFunction(this, n"CancelBlendingIn");
		}
	}

	UFUNCTION()
	private void PlayerStartedInteracting(AHazePlayerCharacter Player,
	                                      ADoubleInteractionActor Interaction,
	                                      UInteractionComponent InteractionComponent)
	{
		NetSetStartInteractionTime(Player, Time::GameTimeSeconds);
	}

	UFUNCTION()
	private void CancelBlendingIn(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                              UInteractionComponent InteractionComponent)
	{
		NetSetStartInteractionTime(Player, -1);
	}

	UFUNCTION(NetFunction)
	private void NetSetStartInteractionTime(AHazePlayerCharacter Player, float StartInteractionTime)
	{
		StartInteractionTimes[Player] = StartInteractionTime;
		UpdateFirstPlayer();
	}

	void UpdateFirstPlayer()
	{
		AHazePlayerCharacter FirstPlayer = GetFirstPlayer();

		if(CurrentFirstPlayer == FirstPlayer)
			return;

		if(CurrentFirstPlayer != nullptr)
		{
			CurrentFirstPlayer.ClearViewSizeOverride(this);
		}

		if(FirstPlayer != nullptr)
		{
			FirstPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Small, EHazeViewPointBlendSpeed::Slow);
		}

		CurrentFirstPlayer = FirstPlayer;
	}

	AHazePlayerCharacter GetFirstPlayer() const
	{
		AHazePlayerCharacter FirstPlayer = nullptr;
		float FirstInteractionTime = BIG_NUMBER;

		for(auto Player : Game::Players)
		{
			float StartInteractionTime = StartInteractionTimes[Player];
			if(StartInteractionTime < 0)
				continue;

			if(StartInteractionTime < FirstInteractionTime)
			{
				FirstPlayer = Player;
				FirstInteractionTime = StartInteractionTime;
			}
		}

		return FirstPlayer;
	}
};