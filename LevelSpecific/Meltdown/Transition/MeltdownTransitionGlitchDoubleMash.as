event void FOnMeltdownTransitionGlitchTriggered();

class AMeltdownTransitionGlitchDoubleMash : ADoubleInteractionActor
{
	UPROPERTY()
	FOnMeltdownTransitionGlitchTriggered OnTransitionGlitchTriggered;

	UPROPERTY(EditAnywhere)
	FSoundDefReference SoundDef;

	bool bInteracting = false;

	UPROPERTY(EditAnywhere)
	FHazePlayBlendSpaceParams BlendInteract;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnDoubleInteractionLockedIn.AddUFunction(this, n"OnBothPlayersInteracted");
		LeftInteraction.OnInteractionStopped.AddUFunction(this, n"ExitedInteraction");
		RightInteraction.OnInteractionStopped.AddUFunction(this, n"ExitedInteraction");
		LeftInteraction.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		RightInteraction.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");

		PreventDoubleInteractionCompletion(this);

		if(SoundDef.IsValid())
			SoundDef.SpawnSoundDefAttached(this);
	}

	UFUNCTION()
	private void ExitedInteraction(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		Player.StopBlendSpace();
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		Player.PlayBlendSpace(BlendInteract);
	}

	UFUNCTION()
	private void OnBothPlayersInteracted()
	{
		bInteracting = true;
		DisableDoubleInteraction(this);

		for (auto Player : Game::Players)
		{
			FButtonMashSettings MashSettings;
			MashSettings.Mode = EButtonMashMode::ButtonHold;
			MashSettings.Duration = 2;
			Player.StartButtonMash(MashSettings, this);
			Player.SetButtonMashAllowCompletion(this, false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HasControl() && bInteracting)
		{

			for(AHazePlayerCharacter Player : Game::Players)
			{
				Player.SetBlendSpaceValues(Player.GetButtonMashProgress(this));
			}
			
			bool bCanComplete = Game::Mio.GetButtonMashProgress(this) >= 0.5 && Game::Zoe.GetButtonMashProgress(this) >= 0.5;
			if (bCanComplete)
			{
				NetTriggerTransition();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetTriggerTransition()
	{
		bInteracting = false;
		OnTransitionGlitchTriggered.Broadcast();
		AllowDoubleInteractionCompletion(this);

		for (auto Player : Game::Players)
		{
			Player.StopButtonMash(this);
		}
	}
};