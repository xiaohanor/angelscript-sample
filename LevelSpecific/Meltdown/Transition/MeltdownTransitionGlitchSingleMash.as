event void FOnButtonMashFinished();

class AMeltdownTransitionGlitchSingleMash : AThreeShotInteractionActor
{
	default Interaction.bPlayerCanCancelInteraction = false;

	UPROPERTY()
	FOnMeltdownTransitionGlitchTriggered OnTransitionGlitchTriggered;

	AHazePlayerCharacter InteractingPlayer = nullptr;

	UPROPERTY()
	FOnButtonMashFinished ButtonMashFinished;

	UPROPERTY(EditAnywhere)
	FHazePlayBlendSpaceParams BlendInteract;

	UFUNCTION(BlueprintPure)
	float GetButtonMashProgression()
	{
		if(InteractingPlayer == nullptr)
			return 0.0;

		return InteractingPlayer.GetButtonMashProgress(this);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnThreeShotEnterBlendingOut.AddUFunction(this, n"OnInteracted");
	}

	UFUNCTION()
	private void OnInteracted(AHazePlayerCharacter Player, AThreeShotInteractionActor InteractionComponent)
	{
		Interaction.Disable(n"Used");

		ButtonMashFinished.Broadcast();

		// FButtonMashSettings MashSettings;
		// MashSettings.Mode = EButtonMashMode::ButtonHold;
		// MashSettings.WidgetPositionOffset = Player.ActorLocation + FVector(90,-90,250);
		// MashSettings.Duration = 1;
		// Player.StartButtonMash(MashSettings, this, FOnButtonMashCompleted(this, n"OnCompletedButtonMash"));
		InteractingPlayer = Player;

		Game::Zoe.PlayBlendSpace(BlendInteract);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(InteractingPlayer != nullptr)
		InteractingPlayer.SetBlendSpaceValues(Game::Zoe.GetButtonMashProgress(this));
	}

	UFUNCTION()
	private void OnCompletedButtonMash()
	{
		Interaction.KickAnyPlayerOutOfInteraction();
		ButtonMashFinished.Broadcast();
	}


};