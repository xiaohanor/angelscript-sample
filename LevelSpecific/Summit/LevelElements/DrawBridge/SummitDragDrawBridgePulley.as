event void ESummitDragDrawBridgePulleyEvent();

class ASummitDragDrawBridgePulley : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent YankRoot;

	UPROPERTY(DefaultComponent, Attach = YankRoot)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinX = -1500.0;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromActorControl;
	default TranslateComp.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MainMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PreviewMeshComp;
	default PreviewMeshComp.SetRelativeLocation(TranslateComp.RelativeLocation + FVector(-1500.0, 0.0, 0.0));
	default PreviewMeshComp.SetHiddenInGame(true);
	default PreviewMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UInteractionComponent LeftPulleyInteractionComp;
	default LeftPulleyInteractionComp.InteractionCapabilityClass = USummitDragDrawBridgePulleyInteractionCapability;
	default LeftPulleyInteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UInteractionComponent RightPulleyInteractionComp;
	default RightPulleyInteractionComp.InteractionCapabilityClass = USummitDragDrawBridgePulleyInteractionCapability;
	default RightPulleyInteractionComp.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedYankRotationDegrees;
	default SyncedYankRotationDegrees.OverrideSyncRate(EHazeCrumbSyncRate::High);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerForce = 1500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float YankPivotAngleMax = 0.3;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float YankPivotAngleSpeed = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float YankImpulse = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect ShadowRumble;

	UPROPERTY()
	ESummitDragDrawBridgePulleyEvent OnBothPlayersInteracted;

	UPROPERTY()
	ESummitDragDrawBridgePulleyEvent OnShadowActivated;

	UPROPERTY()
	ESummitDragDrawBridgePulleyEvent OnCutsceneStart;

	TPerPlayer<FVector> MovementInput;
	TPerPlayer<bool> IsInteracting;
	bool bShadowActivated;

	UPROPERTY(BlueprintReadOnly)
	bool bCutsceneStarted;

	float YankDistance = 0.0;
	float YankVelocity = 0.0;
	FHazeAcceleratedRotator AccYankRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			float PlayerInputAlignment = MAX_flt;
			for(auto Player : Game::Players)
			{
				float Dot = MovementInput[Player].DotProduct(-ActorForwardVector);
				if(Dot < 0.1)
				{
					PlayerInputAlignment = 0.0;
					break;
				}

				PlayerInputAlignment = Math::Min(Dot, PlayerInputAlignment);
			}

			float TargetYankYawAmount = 0.0;
			float MioInputForwardAlignment = MovementInput[Game::Mio].DotProduct(ActorForwardVector);
			float ZoeInputForwardAlignment = MovementInput[Game::Zoe].DotProduct(ActorForwardVector);
			TargetYankYawAmount += MioInputForwardAlignment;
			TargetYankYawAmount -= ZoeInputForwardAlignment;

			FRotator TargetRotation = FRotator(0.0, YankPivotAngleMax * TargetYankYawAmount, 0.0);
			AccYankRotation.AccelerateTo(TargetRotation, YankPivotAngleSpeed, DeltaSeconds);
			TranslateComp.RelativeRotation = AccYankRotation.Value;

			FHazeFrameForceFeedback FrameRumble;
			FrameRumble.LeftMotor = PlayerInputAlignment; 
			FrameRumble.RightMotor = PlayerInputAlignment;
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if(IsInteracting[Player])
					Player.SetFrameForceFeedback(FrameRumble, 0.05); 
			}


			TranslateComp.RelativeRotation = Math::RInterpShortestPathTo(TranslateComp.RelativeRotation, TargetRotation, DeltaSeconds, YankPivotAngleSpeed);
			SyncedYankRotationDegrees.SetValue(TranslateComp.RelativeRotation.Yaw);

			FVector Force = -ActorForwardVector * PlayerInputAlignment * PlayerForce;
			TEMPORAL_LOG(this)
				.Value("Player Input Alignment", PlayerInputAlignment)
			;
			FauxPhysics::ApplyFauxForceToActor(this, Force);
			
			//For shadow
			if (GetPulleyAlpha() < 0.45 && !bShadowActivated)
				CrumbActivateShadow();

			//For cutscene start
			if (GetPulleyAlpha() <= 0.001 && !bCutsceneStarted)
				CrumbActivateCutscene();
		}
		else
		{
			TranslateComp.RelativeRotation = FRotator(0.0, SyncedYankRotationDegrees.Value, 0.0);
		}

		YankDistance += YankVelocity * DeltaSeconds;
		YankVelocity = Math::FInterpTo(YankVelocity, 0, DeltaSeconds, 5);
		YankDistance = Math::FInterpConstantTo(YankDistance, 0, DeltaSeconds, 200);
		YankRoot.RelativeLocation = FVector(-YankDistance, 0.0, 0.0);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbActivateShadow()
	{
		Timer::SetTimer(this, n"DelayRoarFeedback", 0.75, false);
		bShadowActivated = true;
		OnShadowActivated.Broadcast();
	}

	UFUNCTION()
	void DelayRoarFeedback()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayForceFeedback(ShadowRumble,false, false, this); 
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbActivateCutscene()
	{
		bCutsceneStarted = true;
		OnCutsceneStart.Broadcast();
	}

	UFUNCTION(BlueprintPure)
	float GetPulleyAlpha() const property
	{
		return TranslateComp.GetCurrentAlphaBetweenConstraints().X;
	}

	UFUNCTION(BlueprintPure)
	float GetYankRotationAlpha() const property
	{
		return Math::Saturate(Math::Abs(AccYankRotation.Value.Yaw));
	}

	void KickPlayersFromInteraction()
	{
		LeftPulleyInteractionComp.KickAnyPlayerOutOfInteraction();
		RightPulleyInteractionComp.KickAnyPlayerOutOfInteraction();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbAddYankImpulse()
	{
		YankVelocity += YankImpulse;
	}
};