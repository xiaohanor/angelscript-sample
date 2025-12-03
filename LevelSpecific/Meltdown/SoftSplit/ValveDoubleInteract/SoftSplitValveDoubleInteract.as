event void FSoftSplitValveCompletedSignature();

class ASoftSplitValveDoubleInteract : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasySpinRoot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent SciFiSpinRoot;

	UPROPERTY(DefaultComponent, Attach = FantasySpinRoot)
	UInteractionComponent ZoeInteractComp;
	default ZoeInteractComp.bPlayerCanCancelInteraction = false;
	default ZoeInteractComp.InteractionCapabilityClass = USoftSplitValveDoorCapability;

	UPROPERTY(DefaultComponent, Attach = SciFiSpinRoot)
	UInteractionComponent MioInteractComp;
	default MioInteractComp.bPlayerCanCancelInteraction = false;
	default MioInteractComp.InteractionCapabilityClass = USoftSplitValveDoorCapability;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	FButtonMashSettings MashSettings;
	default MashSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
	default MashSettings.bAllowPlayerCancel = false;

	UPROPERTY(EditAnywhere)
	float TotalRotation = 360.0;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraActor;

	UPROPERTY()
	FSoftSplitValveCompletedSignature OnCompleted;

	TPerPlayer<bool> bInteracting;
	TPerPlayer<bool> bPushing;
	TPerPlayer<UButtonMashComponent> MashComp;

	bool bBothInteracting = false;
	bool bBothPushing = false;
	bool bIsSpinning = false;

	float TotalProgress = 0.0;
	float ProgressVelocity = 0.0;

	UFUNCTION(BlueprintPure)
	float GetProgressVelocity()
	{
		return ProgressVelocity;
	}	

	UFUNCTION(BlueprintPure)
	float GetTotalProgress()
	{
		return TotalProgress;
	}	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ZoeInteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		ZoeInteractComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
		MioInteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		MioInteractComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
	}

	float LastTickRotation;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		if (bBothInteracting)
		{
			bool bBothPlayersMashing = true;
			for (auto Player : Game::GetPlayers())
			{
				float MashRate;
				bool bMashingSufficiently;
				Player.GetButtonMashCurrentRate(this, MashRate, bMashingSufficiently);

				if (!bMashingSufficiently)
				{
					bBothPlayersMashing = false;

					if (bPushing[Player])
					{
						if (Player.IsMio())
							USoftSplitValveDoorEffectHandler::Trigger_MioStopPushing(this);
						else
							USoftSplitValveDoorEffectHandler::Trigger_ZoeStopPushing(this);

						bPushing[Player] = false;
					}
				}
				else
				{
					if (!bPushing[Player])
					{
						if (Player.IsMio())
							USoftSplitValveDoorEffectHandler::Trigger_MioStartPushing(this);
						else
							USoftSplitValveDoorEffectHandler::Trigger_ZoeStartPushing(this);

						bPushing[Player] = true;
					}
				}
			}

			if (bBothPlayersMashing)
			{
				ProgressVelocity = Math::Clamp(ProgressVelocity + 0.1 * DeltaSeconds, 0.0, 0.15);

				for (AHazePlayerCharacter Player : Game::Players)
					{
					float FFFrequency = 80.0;
					float FFIntensity = 0.4;
					FHazeFrameForceFeedback FF;
				//	FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
					FF.RightMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
					Player.SetFrameForceFeedback(FF);
					}

				if (!bBothPushing)
				{
					USoftSplitValveDoorEffectHandler::Trigger_BothPlayersStartPushing(this);
					bBothPushing = true;
				}
			}
			else
			{
				ProgressVelocity = Math::Clamp(ProgressVelocity - 0.5 * DeltaSeconds, 0.0, 0.15);

				if (bBothPushing)
				{
					USoftSplitValveDoorEffectHandler::Trigger_BothPlayersStopPushing(this);
					bBothPushing = false;
				}
			}

			TotalProgress = Math::Clamp(TotalProgress + ProgressVelocity * DeltaSeconds, 0, 1);
			bIsSpinning = ProgressVelocity > 0.0;

			FRotator SpinRotation = FRotator(0.0, Math::Lerp(0.0, TotalRotation, TotalProgress), 0.0);

			float CurrentRotationAmount = TotalRotation * TotalProgress;
			if (LastTickRotation > 0)
			{
				float RotDiff = CurrentRotationAmount - LastTickRotation;
				float RotSpeed = RotDiff / DeltaSeconds;
				Print(""+ RotSpeed);

			}

			LastTickRotation = TotalRotation * TotalProgress;



			FantasySpinRoot.SetRelativeRotation(SpinRotation);
			SciFiSpinRoot.SetRelativeRotation(SpinRotation);
			CameraRoot.SetRelativeRotation(FRotator(0.0, TotalProgress * 90.0, 0.0));

			if (Math::IsNearlyEqual(TotalProgress, 1.0))
			{
				if (HasControl())
					NetInteractionCompleted();
			}
		}
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		bInteracting[Player] = true;

		Player.AttachToComponent(InteractionComponent, NAME_None,EAttachmentRule::KeepWorld, 
								EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		if (bInteracting[Game::Zoe] && bInteracting[Game::Mio])
		{
			StartButtonMash();
			USoftSplitValveDoorEffectHandler::Trigger_BothPlayersInteracted(this);
		}
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.StopButtonMash(this);

		bInteracting[Player] = false;
	}

	private void StartButtonMash()
	{
		for (auto Player : Game::GetPlayers())
		{
			FButtonMashSettings PlayerMashSettings = MashSettings;
			if (Player.IsMio())
			{
				PlayerMashSettings.WidgetAttachComponent = MioInteractComp;
				PlayerMashSettings.WidgetPositionOffset = MioInteractComp.WidgetVisualOffset;
			}
			else
			{
				PlayerMashSettings.WidgetAttachComponent = ZoeInteractComp;
				PlayerMashSettings.WidgetPositionOffset = ZoeInteractComp.WidgetVisualOffset;
			}

			Player.StartButtonMash(PlayerMashSettings, this);
			
			MashComp[Player] = UButtonMashComponent::Get(Player);
			MashComp[Player].SetAllowButtonMashCompletion(this, false);	
		}

		bBothInteracting = true;
		Game::Zoe.ActivateCamera(CameraActor, 2.0, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(NetFunction)
	private void NetInteractionCompleted()
	{
		ZoeInteractComp.KickAnyPlayerOutOfInteraction();
		ZoeInteractComp.Disable(this);
		MioInteractComp.KickAnyPlayerOutOfInteraction();
		MioInteractComp.Disable(this);

		OnCompleted.Broadcast();

		TotalProgress = 1.0;
		bBothInteracting = false;

		Game::Zoe.DeactivateCameraByInstigator(this);
		USoftSplitValveDoorEffectHandler::Trigger_Completed(this);
	}
};

	