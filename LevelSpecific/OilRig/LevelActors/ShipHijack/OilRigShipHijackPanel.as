event void FOilRigShipHijackEvent();

class AOilRigShipHijackPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent InteractionRoot;

	UPROPERTY(DefaultComponent, Attach = InteractionRoot)
	UThreeShotInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PanelRoot;

	UPROPERTY(DefaultComponent, Attach = PanelRoot)
	USceneComponent ButtonRoot;

	UPROPERTY(DefaultComponent, Attach = ButtonRoot)
	USceneComponent TutorialAttachmentComp;

	UPROPERTY(DefaultComponent, Attach = PanelRoot)
	USceneComponent PendulumRoot;

	UPROPERTY(DefaultComponent, Attach = PendulumRoot)
	USceneComponent PendulumProgressTracker;

	UPROPERTY(DefaultComponent, Attach = InteractionRoot)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	TArray<UStaticMeshComponent> ProgressLamps;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface LitMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface UnlitMaterial;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ButtonPressedTimeLike;

	UPROPERTY()
	FOilRigShipHijackEvent OnInteractionStarted;

	UPROPERTY()
	FOilRigShipHijackEvent OnInteractionStopped;

	UPROPERTY()
	FOilRigShipHijackEvent OnPlayersLockedIn;

	UPROPERTY()
	TPerPlayer<UHazeLocomotionFeatureBase> LocomotionFeatures;

	UPROPERTY(EditAnywhere)
	AOilRigShipHijackPanel OtherHijackPanel;

	UPROPERTY(EditDefaultsOnly)
	FText TutorialText;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FailForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SuccessForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve PendulumCurve;

	UPROPERTY(EditAnywhere)
	float PendulumTimeOffset = 0.0;

	bool bPendulumActive = true;
	float PendulumProgress = 0.0;
	float PendulumDuration = 2.8;
	float PendulumMaxOffset = 27.0;
	FVector2D PendulumSuccessRange = FVector2D(0.32, 0.68);
	bool bInSuccessRange = false;
	bool bSuccessfulPressDetected = false;
	bool bFailTriggeredThisCycle = false;
	float TimeSinceFail = 0.0;

	int LampsLit = 0;
	bool bHasLockedIn = false;

	AHazePlayerCharacter InteractingPlayer;
	AHazePlayerCharacter LastInteractingPlayer;
	AOilRigShipHijackManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (InteractionComp.UsableByPlayers == EHazeSelectPlayer::Mio)
			SetActorControlSide(Game::Mio);
		else
			SetActorControlSide(Game::Zoe);

		ButtonPressedTimeLike.BindUpdate(this, n"UpdateButtonPressed");
		ButtonPressedTimeLike.BindFinished(this, n"FinishButtonPressed");

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");
		InteractionComp.OnCancelPressed.AddUFunction(this, n"InteractionCancelled");
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		InteractionComp.bPlayerCanCancelInteraction = false;
		InteractingPlayer = Player;
		LastInteractingPlayer = Player;
		FOilRigShipHijackPanelEventParams Params;
		Params.Player = InteractingPlayer;
		Params.NumLampsLit = LampsLit;
		UOilRigShipHijackPanelEffectEventHandler::Trigger_OnStartInteract(this, Params);
		OnInteractionStarted.Broadcast();

		if (Player.HasControl())
			NetAllowCancelOrLockIn(Player);
	}

	UFUNCTION(NetFunction)
	private void NetAllowCancelOrLockIn(AHazePlayerCharacter Player)
	{
		if (!Player.HasControl() || !Network::IsGameNetworked())
		{
			if (OtherHijackPanel.InteractingPlayer != nullptr)
				NetRespondCancelOrLockIn(Player, true);
			else
				NetRespondCancelOrLockIn(Player, false);
		}
	}

	UFUNCTION(NetFunction)
	private void NetRespondCancelOrLockIn(AHazePlayerCharacter Player, bool bLockIn)
	{
		if (bLockIn)
		{
			if (!bHasLockedIn)
			{
				bHasLockedIn = true;
				OtherHijackPanel.bHasLockedIn = true;

				InteractionComp.bPlayerCanCancelInteraction = false;
				OtherHijackPanel.InteractionComp.bPlayerCanCancelInteraction = false;

				OnPlayersLockedIn.Broadcast();
				OtherHijackPanel.OnPlayersLockedIn.Broadcast();
			}
		}
		else
		{
			// If not locked in, allow cancel
			InteractionComp.bPlayerCanCancelInteraction = true;
		}
	}

	UFUNCTION()
	private void InteractionStopped(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		if (InteractingPlayer != nullptr)
		{
			FOilRigShipHijackPanelEventParams Params;
			Params.Player = InteractingPlayer;
			Params.NumLampsLit = LampsLit;
			UOilRigShipHijackPanelEffectEventHandler::Trigger_OnStopInteract(this, Params);
			OnInteractionStopped.Broadcast();
			InteractingPlayer = nullptr;
		}
	}

	UFUNCTION()
	private void InteractionCancelled(AHazePlayerCharacter Player,
	                                  UThreeShotInteractionComponent Interaction)
	{
		if (InteractingPlayer != nullptr)
		{
			FOilRigShipHijackPanelEventParams Params;
			Params.Player = InteractingPlayer;
			Params.NumLampsLit = LampsLit;
			UOilRigShipHijackPanelEffectEventHandler::Trigger_OnStopInteract(this, Params);
			OnInteractionStopped.Broadcast();
			InteractingPlayer = nullptr;
		}
	}


	UFUNCTION()
	void LockPlayerIntoInteraction()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bPendulumActive)
			return;
		
		float CurTime = Time::GetActorControlCrumbTrailTime(this) + PendulumTimeOffset;
		float WrappedTime = Math::Wrap(CurTime, 0.0, PendulumDuration);
		PendulumProgress = PendulumCurve.GetFloatValue(Math::Saturate(WrappedTime/PendulumDuration));

		float ProgressTrackerOffset = Math::Lerp(-PendulumMaxOffset, PendulumMaxOffset, PendulumProgress);
		PendulumProgressTracker.SetRelativeLocation(FVector(7.668794, ProgressTrackerOffset, 25.0));

		if (HasControl())
		{
			if (PendulumProgress > PendulumSuccessRange.X && PendulumProgress < PendulumSuccessRange.Y)
			{
				bInSuccessRange = true;
			}
			else
			{
				if (bInSuccessRange)
				{
					bInSuccessRange = false;
					if (!bSuccessfulPressDetected && !bFailTriggeredThisCycle)
					{
						if (HasControl())
							CrumbFailTriggered(true);
					}

					bSuccessfulPressDetected = false;
					bFailTriggeredThisCycle = false;
				}
			}

			TimeSinceFail += DeltaTime;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSuccessTriggered()
	{
		LampsLit = Math::Clamp(LampsLit + 1, 0, 5);

		for (int i = 0; i < ProgressLamps.Num(); i++)
		{
			if (LampsLit > i)
				ProgressLamps[i].SetMaterial(1, LitMaterial);
		}

		BP_Success();

		FOilRigShipHijackPanelEventParams Params;
		Params.Player = InteractingPlayer;
		Params.NumLampsLit = LampsLit;
		UOilRigShipHijackPanelEffectEventHandler::Trigger_Success(this, Params);

		InteractingPlayer.PlayForceFeedback(SuccessForceFeedback, false, true, this);

		Manager.Success(this);
	}

	void CompleteAll()
	{
		bPendulumActive = false;

		for (int i = 0; i < ProgressLamps.Num(); i++)
			ProgressLamps[i].SetMaterial(1, LitMaterial);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Success() {}

	UFUNCTION(CrumbFunction)
	void CrumbFailTriggered(bool bAutomatic)
	{
		if (LampsLit == 0)
		{
			// So we get a fail event even though no lamps are lit, when user instigated.
			if (!bAutomatic)
				TriggerFailEvent(false);
			return;
		}

		TimeSinceFail = 0.0;

		LampsLit = Math::Clamp(LampsLit - 1, 0, 5);

		for (int i = 0; i < ProgressLamps.Num(); i++)
		{
			if (LampsLit <= i)
				ProgressLamps[i].SetMaterial(1, UnlitMaterial);
		}

		BP_Fail();

		Manager.Fail(this);

		TriggerFailEvent(bAutomatic);
	}

	void TriggerFailEvent(bool bAutomatic)
	{
		if (bAutomatic)
		{
			FOilRigShipHijackPanelEventParams Params;
			Params.Player = LastInteractingPlayer;
			Params.NumLampsLit = LampsLit;
			UOilRigShipHijackPanelEffectEventHandler::Trigger_FailAutomatic(this, Params);
		}
		else
		{
			FOilRigShipHijackPanelEventParams Params;
			Params.Player = LastInteractingPlayer;
			Params.NumLampsLit = LampsLit;
			UOilRigShipHijackPanelEffectEventHandler::Trigger_Fail(this, Params);
		}

		if (InteractingPlayer != nullptr)
			InteractingPlayer.PlayForceFeedback(FailForceFeedback, false, true, this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Fail() {}

	// Returns true if successful
	bool TriggerButtonPressed()
	{
		check(HasControl());

		if (InteractingPlayer == nullptr)
			return false;
		if (ButtonPressedTimeLike.IsPlaying())
			return false;

		if (bInSuccessRange)
		{
			if (!bSuccessfulPressDetected)
			{
				CrumbSuccessTriggered();
				bSuccessfulPressDetected = true;
			}
		}
		else
		{
			if (TimeSinceFail >= 0.4)
			{
				bFailTriggeredThisCycle = true;
				CrumbFailTriggered(false);
			}
		}

		CrumbButtonPressed(bSuccessfulPressDetected);
		return bSuccessfulPressDetected;
	}

	UFUNCTION(CrumbFunction)
	void CrumbButtonPressed(bool bSuccess)
	{
		ButtonPressedTimeLike.PlayFromStart();
		BP_ButtonPressed(bSuccessfulPressDetected);
		InteractingPlayer.SetAnimTrigger(n"TurnKnob");
	}


	UFUNCTION(BlueprintEvent)
	void BP_ButtonPressed(bool bSuccess) {}

	UFUNCTION()
	private void UpdateButtonPressed(float CurValue)
	{
		float Rot = Math::Lerp(0.0, -90.0, CurValue);
		ButtonRoot.SetRelativeRotation(FRotator(0.0, 0.0, Rot));
	}

	UFUNCTION()
	private void FinishButtonPressed()
	{
		BP_ButtonPressFinished();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ButtonPressFinished() {}

	bool AllLampsLit()
	{
		if (LampsLit >= 5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	float GetPendulumProgressAlpha() const
	{
		return PendulumProgress;
	}
}

struct FOilRigShipHijackPanelEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	int NumLampsLit;
}

class UOilRigShipHijackPanelEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Success(FOilRigShipHijackPanelEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void Fail(FOilRigShipHijackPanelEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void FailAutomatic(FOilRigShipHijackPanelEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void OnStartInteract(FOilRigShipHijackPanelEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void OnStopInteract(FOilRigShipHijackPanelEventParams Params) {}
	
}