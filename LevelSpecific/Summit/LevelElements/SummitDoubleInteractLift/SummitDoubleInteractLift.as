event void FASummitDoubleInteractLiftSignature();

UCLASS(Abstract)
class ASummitDoubleInteractLift : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LiftEndPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Lift;

	UPROPERTY(DefaultComponent, Attach = Lift)
	USceneComponent InteractionComponents;

	UPROPERTY(DefaultComponent, Attach = Lift)
	UStaticMeshComponent Valve1;

	UPROPERTY(DefaultComponent, Attach = Lift)
	UStaticMeshComponent Valve2;

	UPROPERTY(DefaultComponent, Attach=InteractionComponents)
	UInteractionComponent MioInteractionComponent;
	default MioInteractionComponent.UsableByPlayers = EHazeSelectPlayer::Mio;
	default MioInteractionComponent.bPlayerCanCancelInteraction = true;
	default MioInteractionComponent.bShowCancelPrompt = true;

	UPROPERTY(DefaultComponent, Attach=InteractionComponents)
	UInteractionComponent ZoeInteractionComponent;
	default ZoeInteractionComponent.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeInteractionComponent.bPlayerCanCancelInteraction = true;
	default ZoeInteractionComponent.bShowCancelPrompt = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent CrumbedLiftLocation;
	default CrumbedLiftLocation.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(DefaultComponent, Attach = Lift)
	USceneComponent WheelRotateRoot;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UHazeLocomotionFeatureBase ElevatorWheelFeature;

	UPROPERTY(EditAnywhere)
	float InterpSpeed = 250.0;

	UPROPERTY(EditAnywhere)
	bool bFakeButtonMash = true;

	/* If button mash completion is above this value for both players, the lift will move upwards using interp speed */
	UPROPERTY(EditAnywhere)
	float ButtonMashMinThreshold = 0.9;

	UPROPERTY(EditAnywhere)
	FButtonMashSettings ButtonMashSettingsZoe;
	default ButtonMashSettingsZoe.Mode = EButtonMashMode::ButtonHold;

	UPROPERTY(EditAnywhere)
	FButtonMashSettings ButtonMashSettingsMio;
	default ButtonMashSettingsMio.Mode = EButtonMashMode::ButtonHold;

	UPROPERTY(EditAnywhere)
	float WheelRotateRevolutionsFullProgress = 5.0;

	FVector StartPosition;
	FVector EndPosition;
	bool bMioInteracting = false;
	bool bZoeInteracting = false;
	bool bCurrentlyButtonMashing = false;
	bool bIsComplete;
	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	TPerPlayer<bool> IsOverButtonMashThreshold;

	UPROPERTY()
	FASummitDoubleInteractLiftSignature OnMoving;

	UPROPERTY()
	FASummitDoubleInteractLiftSignature OnStartedMoving;

	UPROPERTY()
	FASummitDoubleInteractLiftSignature OnCompleted;

	bool bIsMoving;

	default TickGroup = ETickingGroup::TG_HazeInput;

	float AboveThresholdTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPosition = Root.WorldLocation;
		EndPosition = LiftEndPoint.WorldLocation;

		MioInteractionComponent.OnInteractionStarted.AddUFunction(this, n"OnInteractStart");
		MioInteractionComponent.OnInteractionStopped.AddUFunction(this, n"OnInteractStop");

		ZoeInteractionComponent.OnInteractionStarted.AddUFunction(this, n"OnInteractStart");
		ZoeInteractionComponent.OnInteractionStopped.AddUFunction(this, n"OnInteractStop");

		Mio = Game::Mio;
		Zoe = Game::Zoe;

		CrumbedLiftLocation.Value = Root.WorldLocation;

		for(auto Player : Game::Players)
		{
			IsOverButtonMashThreshold[Player] = false;
		}

		SetActorEnableCollision(false);
		SetActorEnableCollision(true);
	}

	UFUNCTION()
	private void OnInteractStart(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.AddLocomotionFeature(ElevatorWheelFeature, this);
		Player.AttachToComponent(Component, AttachmentRule = EAttachmentRule::KeepWorld);
		Component.bPlayerCanCancelInteraction = false;

		if(Player.IsMio())
		{
			bMioInteracting = true;
		}
		else
		{
			bZoeInteracting = true;
		}

		if (!Player.HasControl() || !Network::IsGameNetworked())
		{
			if (bMioInteracting && bZoeInteracting)
			{
				NetInteractionSuccess(Player, Component);

				if (bFakeButtonMash)
				{
					CrumbedLiftLocation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
				}
			}
			else
			{
				NetReleaseCancel(Player, Component);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetInteractionSuccess(AHazePlayerCharacter Player, UInteractionComponent Comp)
	{
		if (bFakeButtonMash)
		{
			OnMoving.Broadcast();
			return;
		}

		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.OtherPlayer.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		MioInteractionComponent.bPlayerCanCancelInteraction = false;
		ZoeInteractionComponent.bPlayerCanCancelInteraction = false;

		ButtonMashSettingsMio.WidgetAttachComponent = MioInteractionComponent;
		Mio.StartButtonMash(ButtonMashSettingsMio, this);
		Mio.SetButtonMashAllowCompletion(this, false);

		ButtonMashSettingsZoe.WidgetAttachComponent = ZoeInteractionComponent;
		Zoe.StartButtonMash(ButtonMashSettingsZoe, this);
		Zoe.SetButtonMashAllowCompletion(this, false);
		
		bCurrentlyButtonMashing = true;
		OnMoving.Broadcast();
		CrumbedLiftLocation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		USummitDoubleInteractLiftEventHandler::Trigger_OnLiftStarted(this);
	}

	UFUNCTION(NetFunction)
	void NetReleaseCancel(AHazePlayerCharacter Player, UInteractionComponent Comp)
	{
		Comp.bPlayerCanCancelInteraction = true;
	}

	UFUNCTION()
	private void OnInteractStop(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.RemoveLocomotionFeature(ElevatorWheelFeature, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		if(Player.IsMio())
			bMioInteracting = false;
		else
			bZoeInteracting = false;

		if(bCurrentlyButtonMashing)
		{
			Mio.StopButtonMash(this);
			Zoe.StopButtonMash(this);

			bCurrentlyButtonMashing = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		if(bMioInteracting
		&& Game::Mio.Mesh.CanRequestLocomotion())
			Game::Mio.RequestLocomotion(n"ElevatorWheel", this);
		if(bZoeInteracting
		&& Game::Zoe.Mesh.CanRequestLocomotion())
			Game::Zoe.RequestLocomotion(n"ElevatorWheel", this);

		if(!bMioInteracting || !bZoeInteracting)
			return;
		
		if (bIsMoving)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				float FFFrequency = 30.0;
				float FFIntensity = 0.6;
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF);
			}

			Valve1.AddRelativeRotation(FRotator(0,0,-180) * DeltaSeconds);
			Valve2.AddRelativeRotation(FRotator(0,0,-180) * DeltaSeconds);
		}

		HandleProgress(DeltaSeconds);

		bool bMioIsOverThreshold = IsOverButtonMashThreshold[Game::Mio];
		bool bZoeIsOverThreshold = IsOverButtonMashThreshold[Game::Zoe];

		TEMPORAL_LOG(this)
			.Value("Mio is over button mash Threshold", bMioIsOverThreshold)
			.Value("Zoe is over button mash Threshold", bZoeIsOverThreshold)
		;
	}

	void SetWheelRotation(float MoveAlpha)
	{
		WheelRotateRoot.RelativeRotation = FRotator(-360.0 * WheelRotateRevolutionsFullProgress * MoveAlpha, 0.0, 0.0);
	}

	float GetMoveAlpha()
	{
		FVector StartToEndDelta = EndPosition - StartPosition;
		FVector TravelDir = StartToEndDelta.GetSafeNormal();
		FVector DeltaToCurrent = Root.WorldLocation - StartPosition;
		float TotalMoveAmount = StartToEndDelta.DotProduct(TravelDir);
		float MovedAmount = DeltaToCurrent.DotProduct(TravelDir);
		return MovedAmount / TotalMoveAmount;
	}

	void HandleProgress(float DeltaTime)
	{
		if (!bFakeButtonMash)
		{
			if(HasControl())
			{
				for(auto Player : Game::Players)
				{
					float ButtonMashProgress = Player.GetButtonMashProgress(this);

					if(ButtonMashProgress > ButtonMashMinThreshold)
					{
						if(!IsOverButtonMashThreshold[Player])
							CrumbSetButtonMashStatusOnPlayer(Player, true);
					}
					else
					{
						if(IsOverButtonMashThreshold[Player])
							CrumbSetButtonMashStatusOnPlayer(Player, false);
					}
				}
			}

			bool bEitherIsUnderThreshold = false;
			for(auto bButtonMashState : IsOverButtonMashThreshold)
			{
				if(!bButtonMashState)
				{
					bEitherIsUnderThreshold = true;
					break;
				}
			}

			if(bEitherIsUnderThreshold)
			{
				// BP_StopWheelsAnim();
				if (bIsMoving)
					USummitDoubleInteractLiftEventHandler::Trigger_OnLiftStopped(this);

				AboveThresholdTime = 0;
				bIsMoving = false;
				for(auto Player : Game::Players)
				{
					Player.SetAnimBoolParam(n"Is Spinning Lift Wheel", false);
				}
				return;
			}
			else
			{
				for(auto Player : Game::Players)
				{
					Player.SetAnimBoolParam(n"Is Spinning Lift Wheel", true);
				}
			}
		}

		float MoveAlpha = GetMoveAlpha();
		SetWheelRotation(MoveAlpha);
		if (!bIsComplete)
		{
			// BP_WheelsAnim();
			if (!bIsMoving)
			{
				USummitDoubleInteractLiftEventHandler::Trigger_OnLiftMoving(this); 
				OnStartedMoving.Broadcast();
			}
				
			bIsMoving = true;
			
		}

		if(HasControl())
		{
			AboveThresholdTime += DeltaTime;
			//ease the targetspeed based on distance traveled
			float TargetInterpSpeed = InterpSpeed;
			if (MoveAlpha < 0.2)
				TargetInterpSpeed = Math::SinusoidalInOut(InterpSpeed * 0.8, InterpSpeed, MoveAlpha / 0.2);
			else if (MoveAlpha > 0.8)
				TargetInterpSpeed = Math::SinusoidalInOut(InterpSpeed * 0.8, InterpSpeed, (1 - MoveAlpha) / 0.2);

			//ease the current speed based on duration we've been mashing/holding above threshold
			float CurrentInterpSpeed = Math::SinusoidalIn(0, TargetInterpSpeed, Math::Saturate(AboveThresholdTime / 0.5));
			Root.WorldLocation = Math::VInterpConstantTo(Root.WorldLocation, EndPosition, DeltaTime, CurrentInterpSpeed);
			CrumbedLiftLocation.SetValue(Root.WorldLocation);
			if(Root.WorldLocation.Equals(EndPosition))
				CrumbComplete();
		}
		else
		{
			Root.WorldLocation = CrumbedLiftLocation.Value;
		}
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbSetButtonMashStatusOnPlayer(AHazePlayerCharacter PlayerToSet, bool bIsOverThreshold)
	{
		IsOverButtonMashThreshold[PlayerToSet] = bIsOverThreshold;
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	void CrumbComplete()
	{
		Root.WorldLocation = EndPosition;
		SetActorTickEnabled(false);
		OnCompleted.Broadcast();
		USummitDoubleInteractLiftEventHandler::Trigger_OnLiftFinished(this);

		for (AHazePlayerCharacter Player : Game::Players)
			Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		if(bCurrentlyButtonMashing)
		{
			Mio.StopButtonMash(this);
			Zoe.StopButtonMash(this);

			bCurrentlyButtonMashing = false;
		}

		CrumbedLiftLocation.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		MioInteractionComponent.Disable(this);
		ZoeInteractionComponent.Disable(this);
		MioInteractionComponent.KickAnyPlayerOutOfInteraction();
		ZoeInteractionComponent.KickAnyPlayerOutOfInteraction();
		bIsComplete = true;
	}

	UFUNCTION()
	void SetLiftAtEndPosition()
	{
		Timer::SetTimer(this, n"HandleLiftAtEndPosition", 0.1);
	}

	UFUNCTION()
	void HandleLiftAtEndPosition()
	{
		Root.WorldLocation = EndPosition;
		ZoeInteractionComponent.DisableForPlayer(Zoe, this);
		MioInteractionComponent.DisableForPlayer(Mio, this);
		SetActorEnableCollision(false);
		SetActorEnableCollision(true);
	}

	UFUNCTION()
	void SetEndState()
	{
		MioInteractionComponent.Disable(this);
		ZoeInteractionComponent.Disable(this);
		Root.WorldLocation = EndPosition;
		SetActorEnableCollision(false);
		SetActorEnableCollision(true);
	}

	UFUNCTION(BlueprintEvent)
	void BP_WheelsAnim()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_StopWheelsAnim()
	{

	}
}