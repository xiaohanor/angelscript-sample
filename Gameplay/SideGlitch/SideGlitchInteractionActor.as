event void FOnSideGlitchEntered();

// We only care about Aborted/Completed.
enum ESideGlitchState
{
	None,
	Aborted,
	Completed,
}

class ASideGlitchInteractionActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent GlitchRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UThreeShotInteractionComponent MioInteraction;
	default MioInteraction.RelativeLocation = FVector(-160.0, -70.0, -150.0);
	default MioInteraction.RelativeRotation = FRotator(0, 15, 0);
	default MioInteraction.MovementSettings = FMoveToParams::AnimateTo();
	default MioInteraction.UsableByPlayers = EHazeSelectPlayer::Mio;
	default MioInteraction.bShowForOtherPlayer = true;

	UPROPERTY(DefaultComponent, Attach = MioInteraction)
	USceneComponent MioButtonMashAttachComp;
	default MioButtonMashAttachComp.RelativeLocation = FVector(100.0, 20.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = Root)
	UThreeShotInteractionComponent ZoeInteraction;
	default ZoeInteraction.RelativeLocation = FVector(-160.0, 70.0, -150.0);
	default ZoeInteraction.RelativeRotation = FRotator(0, -15, 0);
	default ZoeInteraction.MovementSettings = FMoveToParams::AnimateTo();
	default ZoeInteraction.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeInteraction.bShowForOtherPlayer = true;

	UPROPERTY(DefaultComponent, Attach = ZoeInteraction)
	USceneComponent ZoeButtonMashAttachComp;
	default ZoeButtonMashAttachComp.RelativeLocation = FVector(100.0, -20.0, 180.0);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;
	default DisableComponent.AutoDisableRange = 10000.0;
	default DisableComponent.bAutoDisable = true;

	UPROPERTY(EditAnywhere, Category = "Side Glitch")
	FHazeProgressPointRef SideGlitchProgressPoint;

	UPROPERTY(EditAnywhere)
	bool bFadeToWhiteWhenEntering = true;

	UPROPERTY(EditAnywhere)
	bool bIsOnDragon = false;

	UPROPERTY(EditAnywhere)
	TPerPlayer<FHazePlayBlendSpaceParams> Mh;

	/**
	 * Called when the players want to enter the side glitch.
	 * 
	 * OBS! If you bind anything to this event, make sure to call `ActivateSideStory` on the side glitch actor,
	 * which will cause the game to actually load the side glitch.
	 */
	UPROPERTY()
	FOnSideGlitchEntered OnSideGlitchEntered;

	// Implemented for VO.
	UPROPERTY(BlueprintReadOnly)
	ESideGlitchState SideGlitchState = ESideGlitchState::None;

	TPerPlayer<bool> IsPlayerInteracting;
	bool bTriggered = false;
	bool bHasCheckedForExit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SideGlitchState = ESideGlitchState::None;

		MioInteraction.OnEnterBlendedIn.AddUFunction(this, n"OnPlayerEntered");
		MioInteraction.OnEnterBlendingOut.AddUFunction(this, n"OnEnterBlendingOut");
		MioInteraction.OnExitBlendedIn.AddUFunction(this, n"OnPlayerExited");

		ZoeInteraction.OnEnterBlendedIn.AddUFunction(this, n"OnPlayerEntered");
		ZoeInteraction.OnEnterBlendingOut.AddUFunction(this, n"OnEnterBlendingOut");
		ZoeInteraction.OnExitBlendedIn.AddUFunction(this, n"OnPlayerExited");
	}

	UFUNCTION()
	void OnEnterBlendingOut(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		Player.PlayBlendSpace(Mh[Player]);
	}
	

	UFUNCTION()
	private void OnPlayerEntered(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		IsPlayerInteracting[Player] = true;

		FButtonMashSettings MashSettings;
		MashSettings.Mode = EButtonMashMode::ButtonHold;
		MashSettings.WidgetAttachComponent = Player.IsMio() ? MioButtonMashAttachComp : ZoeButtonMashAttachComp;
		
		MashSettings.Duration = 1.0;
		Player.StartButtonMash(MashSettings, this);
		Player.SetButtonMashAllowCompletion(this, false);

		SetActorTickEnabled(true);

		FSideGlitchInteractionPlayerParams Params;
		Params.Player = Player;
		USideGlitchInteractionEffectHandler::Trigger_OnPlayerEnteredInteraction(this, Params);
	}

	UFUNCTION()
	private void OnPlayerExited(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction)
	{
		IsPlayerInteracting[Player] = false;
		Player.StopButtonMash(this);

		Player.StopBlendSpace();

		if (!IsPlayerInteracting[EHazePlayer::Mio] && !IsPlayerInteracting[EHazePlayer::Zoe])
			SetActorTickEnabled(false);

		FSideGlitchInteractionPlayerParams Params;
		Params.Player = Player;
		USideGlitchInteractionEffectHandler::Trigger_OnPlayerExitedInteraction(this, Params);
	}

	UFUNCTION()
	void OnSideStoryAborted()
	{
		USideGlitchInteractionEffectHandler::Trigger_OnExitSideStoryAborted(this);
		SideGlitchState = ESideGlitchState::Aborted;
	}

	UFUNCTION()
	void OnSideStoryCompleted()
	{
		USideGlitchInteractionEffectHandler::Trigger_OnExitSideStoryComplete(this);
		SideGlitchState = ESideGlitchState::Completed;
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HasControl() && IsPlayerInteracting[EHazePlayer::Mio] && IsPlayerInteracting[EHazePlayer::Zoe])
		{
			float MioProgress = Game::Mio.GetButtonMashProgress(this);
			float ZoeProgress = Game::Zoe.GetButtonMashProgress(this);
			if (MioProgress >= 0.95 && ZoeProgress >= 0.95 && !bTriggered)
			{
				NetTriggerSidePortal();
			}
		}

		if (!IsPlayerInteracting[EHazePlayer::Mio] && !IsPlayerInteracting[EHazePlayer::Zoe])
			SetActorTickEnabled(false);

		if (IsPlayerInteracting[EHazePlayer::Mio])
		{
			float MioProgress = Game::Mio.GetButtonMashProgress(this);
			if (bTriggered)
				MioProgress = 1.0;
			float BlendSpaceValue = BezierCurve::GetLocation_2CP(FVector::ZeroVector, FVector(0.5, 0, 0), FVector(0.5, 0, 1), FVector::OneVector, MioProgress).Z;
			Game::Mio.SetBlendSpaceValues(BlendSpaceValue);
		}
		if (IsPlayerInteracting[EHazePlayer::Zoe])
		{
			float ZoeProgress = Game::Zoe.GetButtonMashProgress(this);
			if (bTriggered)
				ZoeProgress = 1.0;
			float BlendSpaceValue = BezierCurve::GetLocation_2CP(FVector::ZeroVector, FVector(0.5, 0, 0), FVector(0.5, 0, 1), FVector::OneVector, ZoeProgress).Z;
			Game::Zoe.SetBlendSpaceValues(BlendSpaceValue);
		}
	}

	UFUNCTION(NetFunction)
	private void NetTriggerSidePortal()
	{
		bTriggered = true;
		USideGlitchInteractionEffectHandler::Trigger_OnPlayersEnteringSideStory(this);

		if (OnSideGlitchEntered.IsBound())
		{
			// The level wants to do something custom, rely on the level script to
			// eventually call ActivateSideStory
			OnSideGlitchEntered.Broadcast();
		}
		else
		{
			if (bFadeToWhiteWhenEntering)
			{
				FadeFullscreenToColor(this, FLinearColor::White);
				Timer::SetTimer(this, n"ActivateSideStory", 0.5);
			}
			else
			{
				ActivateSideStory();
			}
		}
	}

	UFUNCTION()
	void ActivateSideStory()
	{
		FString ProgressPointID = Progress::GetProgressPointRefID(SideGlitchProgressPoint);
		Progress::PrepareProgressPoint(ProgressPointID);
		Progress::ActivateProgressPoint(ProgressPointID, false);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		CreatePlayerEditorVisualizer(MioInteraction, EHazePlayer::Mio, FTransform::Identity);
		CreateInteractionEditorVisualizer(MioInteraction, EHazeSelectPlayer::Mio);

		CreatePlayerEditorVisualizer(ZoeInteraction, EHazePlayer::Zoe, FTransform::Identity);
		CreateInteractionEditorVisualizer(ZoeInteraction, EHazeSelectPlayer::Zoe);
#endif
	}
};