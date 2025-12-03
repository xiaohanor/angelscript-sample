event void FOnOxygenSuccesfull();
event void FOnOxygenStarted();
event void FOnOxygenEventsVO(AHazePlayerCharacter Player);
struct FSpaceWalkOxygenInteractionClampHolder
{
	UStaticMeshComponent Clamp;
	FRotator StartRotation;
	FRotator EndRotation;

	FSpaceWalkOxygenInteractionClampHolder(UStaticMeshComponent _Clamp)
	{
		Clamp = _Clamp;
	}

}

class ASpaceWalkOxygenInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MioLocation;

	UPROPERTY(DefaultComponent, Attach = TankRoot)
	USceneComponent WidgetLocation;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent Translate;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TankTop;

	UPROPERTY(DefaultComponent, Attach = TankTop)
	UStaticMeshComponent Clamp01;

	UPROPERTY(DefaultComponent, Attach = TankTop)
	UStaticMeshComponent Clamp02;

	UPROPERTY(DefaultComponent, Attach = TankTop)
	UStaticMeshComponent Clamp03;

	UPROPERTY(DefaultComponent, Attach = TankTop)
	UStaticMeshComponent Clamp04;

	UPROPERTY(DefaultComponent, Attach = TankTop)
	UStaticMeshComponent Clamp05;

	UPROPERTY(DefaultComponent, Attach = TankTop)
	UStaticMeshComponent Clamp06;

	UPROPERTY(DefaultComponent, Attach = TankTop)
	UStaticMeshComponent Clamp07;

	UPROPERTY(DefaultComponent, Attach = TankTop)
	UStaticMeshComponent Clamp08;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset AttachCameraSettings;

	TArray<FSpaceWalkOxygenInteractionClampHolder> Clamps;

	UPROPERTY(DefaultComponent, Attach = TankRoot)
	UFauxPhysicsWeightComponent Weight;
	default Weight.bApplyGravity = false;

	UPROPERTY(DefaultComponent, Attach = WidgetLocation)
	UWidgetComponent WidgetComp;
	default WidgetComp.ManuallyRedraw = true;
	default WidgetComp.DrawSize = FVector2D(600, 440);
	default WidgetComp.TickWhenOffscreen = true;

	UPROPERTY(DefaultComponent, Attach = WidgetLocation)
	USceneComponent MioTutorialLocation;
	UPROPERTY(DefaultComponent, Attach = WidgetLocation)
	USceneComponent ZoeTutorialLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent ZoeLocation;

	UPROPERTY(DefaultComponent)
	USpaceWalkHookPointComponent HookPoint;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent OxygenCam;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent EjectPuff;

	UPROPERTY(DefaultComponent, Attach = Translate)
	UStaticMeshComponent TankRoot;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect PumpFF;

	UPROPERTY(EditAnywhere)
	bool bIsInCutscene;
	
	UPROPERTY()
	TSubclassOf<USpaceWalkOxygenInteractionTimingWidget> TimingWidgetClass;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = "MioLocation")
	UEditorBillboardComponent MioBillboard;
	UPROPERTY(DefaultComponent, Attach = "ZoeLocation")
	UEditorBillboardComponent ZoeBillboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent EnterTrigger;

	// What speed to start the first pump of the interaction at
	UPROPERTY(EditAnywhere)
	float PumpStartingSpeed = 1.0;

	TPerPlayer<bool> HasEntered;
	TPerPlayer<bool> IsReadyToInteract;
	float BothPlayersInteractedTime = 0.0;

	float Timer = 0.0;
	int SuccessfulPumps = 0;
	bool bPumpingStarted = false;
	bool bCompleted = false;
	bool bHasFailed = false;
	float SuccessPoint = 1.0;

	AHazePlayerCharacter ActivePlayer;

	bool bTimingActivated = false;
	USpaceWalkOxygenInteractionTimingWidget TimingWidget;
	float DelayUntilMove;

	UPROPERTY()
	FOnOxygenSuccesfull OxygenSucesfull;

	UPROPERTY()
	FOnOxygenStarted OxygenStarted;

	FHazeTimeLike MoveClamps;
	default MoveClamps.Duration = 2.0;
	default MoveClamps.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FOnOxygenEventsVO OnOxygenTankInteractionStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnterTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEntered");

		Translate.OnConstraintHit.AddUFunction(this, n"ConstraintHit");

		MoveClamps.BindUpdate(this, n"UpdateClamps");

		Clamps.Add(FSpaceWalkOxygenInteractionClampHolder(Clamp01));
		Clamps.Add(FSpaceWalkOxygenInteractionClampHolder(Clamp02));
		Clamps.Add(FSpaceWalkOxygenInteractionClampHolder(Clamp03));
		Clamps.Add(FSpaceWalkOxygenInteractionClampHolder(Clamp04));
		Clamps.Add(FSpaceWalkOxygenInteractionClampHolder(Clamp05));
		Clamps.Add(FSpaceWalkOxygenInteractionClampHolder(Clamp06));
		Clamps.Add(FSpaceWalkOxygenInteractionClampHolder(Clamp07));
		Clamps.Add(FSpaceWalkOxygenInteractionClampHolder(Clamp08));

		for (FSpaceWalkOxygenInteractionClampHolder& Clamp : Clamps)
		{
			Clamp.StartRotation = Clamp.Clamp.RelativeRotation;
			Clamp.EndRotation = Clamp.StartRotation + FRotator(0,0,90.0);
		}
	}

	UFUNCTION()
	private void UpdateClamps(float CurrentValue)
	{
		for (FSpaceWalkOxygenInteractionClampHolder& Clamp : Clamps)
		{
			Clamp.Clamp.SetRelativeRotation(Math::LerpShortestPath(Clamp.StartRotation,Clamp.EndRotation, CurrentValue));
		}
	}

	UFUNCTION()
	private void ConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		TankRoot.AddComponentVisualsBlocker(this);
	}

	UFUNCTION()
	private void OnPlayerEntered(AHazePlayerCharacter Player)
	{
		if (Player.HasControl() && IsAllowedToEnter(Player))
			CrumbPlayerEntered(Player);
		OnOxygenTankInteractionStarted.Broadcast(Player);

	}

	bool IsAllowedToEnter(AHazePlayerCharacter Player) const
	{
		auto OtherPlayerOxyComp = USpaceWalkOxygenPlayerComponent::Get(Player.OtherPlayer);
		if (OtherPlayerOxyComp.OxygenInteraction != nullptr && OtherPlayerOxyComp.OxygenInteraction != this)
			return false;
		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlayerEntered(AHazePlayerCharacter Player)
	{
		HasEntered[Player] = true;
		bTimingActivated = false;

		if(AttachCameraSettings != nullptr)
		Player.ApplyCameraSettings(AttachCameraSettings, 2.0,this);

		auto OxyComp = USpaceWalkOxygenPlayerComponent::Get(Player);
		OxyComp.OxygenInteraction = this;

		if (HasControl() && ActivePlayer == nullptr)
		{
			CrumbStartWithActivePlayer(Player);
		}

		if (HasEntered[Player.OtherPlayer])
		{
			EnterTrigger.DisableTrigger(this);
			HookPoint.Disable(this);

			OxygenStarted.Broadcast();

			UHazeCameraComponent Camera = OxygenCam;
			Game::Mio.ActivateCamera(Camera, 2.0, this, EHazeCameraPriority::Default);

			Camera::BlendToFullScreenUsingProjectionOffset(Game::Mio, this, 2.0, 2.0);
			BothPlayersInteractedTime = Time::GameTimeSeconds;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartWithActivePlayer(AHazePlayerCharacter Player)
	{
		devCheck(ActivePlayer == nullptr);
		ActivePlayer = Player;
		UpdateTutorials();
	}

	bool AreBothPlayersReadyToInteract()
	{
		return IsReadyToInteract[0] && IsReadyToInteract[1] && Time::GetGameTimeSince(BothPlayersInteractedTime) > 2.5
			&& !bCompleted && ActivePlayer != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (AreBothPlayersReadyToInteract())
		{
			auto OxygenSettings = USpaceWalkOxygenSettings::GetSettings(Game::Mio);
			if (TimingWidget == nullptr)
			{
				TimingWidget = Cast<USpaceWalkOxygenInteractionTimingWidget>(WidgetComp.GetWidget());
				TimingWidget.StartPumping();
				DelayUntilMove = 1.0;
				WidgetComp.ManuallyRedraw = false;
			}

			if (bHasFailed)
			{
				Timer += DeltaSeconds;
				TimingWidget.UpdateFailedState(true);
				if (Timer >= 1.0 && ActivePlayer.HasControl())
					bHasFailed = false;
			}
			else if (bPumpingStarted)
			{
				TimingWidget.UpdateFailedState(false);

				float SuccessSize = OxygenSettings.OxygenTimingSuccessPct - OxygenSettings.OxygenTimingSuccessShrinkPerPump * SuccessfulPumps;
				float Speed = PumpStartingSpeed + OxygenSettings.SpeedUpPerPumpCycle * SuccessfulPumps;

				if (DelayUntilMove > 0.0)
					DelayUntilMove -= DeltaSeconds;
				else
					Timer += DeltaSeconds * Speed;

				if (Timer >= OxygenSettings.OxygenTimingCycleDuration)
				{
					if (ActivePlayer.HasControl())
						NetPumpFail(false);
				}

				float SuccessMin = OxygenSettings.OxygenTimingCycleDuration * (SuccessPoint - SuccessSize);
				float SuccessMax = OxygenSettings.OxygenTimingCycleDuration * SuccessPoint;

				bool bWouldBeSuccess = Timer >= SuccessMin && Timer <= SuccessMax;
				float TimingPct = Math::Saturate(Timer / OxygenSettings.OxygenTimingCycleDuration);

				TimingWidget.UpdateTiming(ActivePlayer.Player, TimingPct, bWouldBeSuccess);
				TimingWidget.UpdateSuccessWindow(ActivePlayer.Player, SuccessPoint, SuccessSize);
			}
			else
			{
				if (ActivePlayer.HasControl())
				{
					if (SuccessfulPumps < 2)
						NetStartPumping(1.0);
					else
						NetStartPumping(Math::RandRange(1.0 - OxygenSettings.OxygenTimingRandomizationWindow, 1.0));
				}
			}

		}
	}

	void Pump()
	{
		if (ActivePlayer.HasControl())
		{
			auto OxygenSettings = USpaceWalkOxygenSettings::GetSettings(Game::Mio);
			float SuccessSize = OxygenSettings.OxygenTimingSuccessPct - OxygenSettings.OxygenTimingSuccessShrinkPerPump * SuccessfulPumps;
			ActivePlayer.PlayForceFeedback(PumpFF,false,false,this);

			float SuccessMin = OxygenSettings.OxygenTimingCycleDuration * (SuccessPoint - SuccessSize);
			float SuccessMax = OxygenSettings.OxygenTimingCycleDuration * SuccessPoint;

			if (Timer >= SuccessMin && Timer <= SuccessMax)
			{
				NetPumpSuccess();
			}
			else
			{
				NetPumpFail(true);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetPumpSuccess()
	{
		AHazePlayerCharacter PumpingPlayer = ActivePlayer;
		auto OxygenSettings = USpaceWalkOxygenSettings::GetSettings(Game::Mio);

		auto OxygenComp = USpaceWalkOxygenPlayerComponent::Get(ActivePlayer);
		OxygenComp.AnimTouchScreenConfirm.Set();

		FSpaceWalkOxygenInteractionEffectParams EffectParams;
		EffectParams.Player = ActivePlayer;
		USpaceWalkOxygenInteractionEffectHandler::Trigger_OxygenPumpSuccesful(this, EffectParams);

		if (TimingWidget != nullptr)
		{
			if (PumpingPlayer.IsMio())
				TimingWidget.PushLeft();
			else
				TimingWidget.PushRight();
		}

		SuccessfulPumps += 1;
		if (SuccessfulPumps >= OxygenSettings.RequiredOxygenPumps)
		{
			TakeOxygenCompleted();
			return;
		}

		ActivePlayer = ActivePlayer.GetOtherPlayer();
		Timer = 0.0;
		bPumpingStarted = false;

		if (TimingWidget != nullptr)
		{
			TimingWidget.PumpSuccess();
			TimingWidget.UpdateCompletion(float(SuccessfulPumps) / float(OxygenSettings.RequiredOxygenPumps));
		}

		UpdateTutorials();
	}

	UFUNCTION(NetFunction)
	void NetPumpFail(bool bWasPress)
	{
		AHazePlayerCharacter PumpingPlayer = ActivePlayer;
		if (bWasPress)
		{
			auto OxygenComp = USpaceWalkOxygenPlayerComponent::Get(ActivePlayer);
			OxygenComp.AnimTouchScreenConfirm.Set();
		}

		FSpaceWalkOxygenInteractionEffectParams EffectParams;
		EffectParams.Player = ActivePlayer;
		if (bWasPress)
			USpaceWalkOxygenInteractionEffectHandler::Trigger_OxygenPumpFailed(this, EffectParams);
		else
			USpaceWalkOxygenInteractionEffectHandler::Trigger_OxygenFailedTimeout(this, EffectParams);

		SuccessfulPumps = 0;
		Timer = 0.0;
		bPumpingStarted = false;
		bHasFailed = true;
		ActivePlayer = ActivePlayer.GetOtherPlayer();

		if (TimingWidget != nullptr)
		{
			if (PumpingPlayer.IsMio())
				TimingWidget.PushLeft();
			else
				TimingWidget.PushRight();

			TimingWidget.PumpFail();
			TimingWidget.UpdateCompletion(0.0);
		}

		UpdateTutorials();
	}

	void UpdateTutorials()
	{
		for (auto Player : Game::Players)
		{
			auto OxyComp = USpaceWalkOxygenPlayerComponent::Get(Player);
			if (Player == ActivePlayer && bPumpingStarted && OxyComp.OxygenLevel > 0.0)
			{
				FTutorialPrompt Prompt;
				Prompt.Action = ActionNames::Interaction;
				Prompt.DisplayType = ETutorialPromptDisplay::Action;
				Prompt.Text = NSLOCTEXT("SpaceWalkOxygen", "PumpTutorial", "Pump");

				USceneComponent Location;
				if (Player.IsMio())
					Location = MioTutorialLocation;
				else
					Location = ZoeTutorialLocation;

				Player.ShowTutorialPromptWorldSpace(Prompt, this, Location, FVector::ZeroVector, 0.0);
			}
			
		}
	}

	UFUNCTION(NetFunction)
	void NetStartPumping(float InSuccessPoint)
	{
		SuccessPoint = InSuccessPoint;
		bPumpingStarted = true;
		bHasFailed = false;
		Timer = 0.0;
		UpdateTutorials();
	}

	private void TakeOxygenCompleted()
	{
		for (auto Player : Game::Players)
		{
			auto OxyComp = USpaceWalkOxygenPlayerComponent::Get(Player);
			OxyComp.OxygenInteraction = nullptr;
			OxyComp.OxygenLevel = 1.0;
		}

		Game::Mio.DeactivateCameraByInstigator(this, 5.0);
		
		if(!bIsInCutscene)
			Camera::BlendToSplitScreenUsingProjectionOffset(this, 5.0);

		bCompleted = true;
		OxygenSucesfull.Broadcast();
		EjectPuff.Activate();
		Timer::SetTimer(this, n"StopBlowing", 2.0);
		Succes();
		MoveClamps.Play();

		for(AHazePlayerCharacter Clear: Game::Players)
			{
				Clear.RemoveTutorialPromptByInstigator(this);
			}

		if (TimingWidget != nullptr)
			TimingWidget.InteractionCompleted();

		WidgetComp.ManuallyRedraw = true;
		TimingWidget = nullptr;
		
		USpaceWalkOxygenInteractionEffectHandler::Trigger_OxygenCompleted(this);
	}

	UFUNCTION(BlueprintCallable)
	void CustomClearProjection()
	{
		Camera::BlendToSplitScreenUsingProjectionOffset(this, 2.0);
	}

	UFUNCTION()
	void StopBlowing()
	{
		EjectPuff.Deactivate();
		WidgetComp.AddComponentVisualsBlocker(this);
	}

	UFUNCTION()
	void Succes()
	{
		Weight.bApplyGravity = true;
		
		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearCameraSettingsByInstigator(this);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SkipOxygen()
	{
		TakeOxygenCompleted();
	}

	
};