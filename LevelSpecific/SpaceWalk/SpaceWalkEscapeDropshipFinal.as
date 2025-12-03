event void FOnBothPlayersHacking();
event void FOnGameOver();
event void FonHackComplete();
event void FOnFirstHackComplete();
event void FOnPlayerInteractingLastShuttle(AHazePlayerCharacter Player);

struct FSpaceWalkHackingPlayerState
{
	int ShapeIndex = 0;
	bool bActivated = false;
	bool bRequestedDeactivation = false;
	bool bDeactivated = false;
	float Timer = 0.0;
};

class ASpaceWalkEscapeDropshipFinal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	AStaticMeshActor DropShipLocation;
	
	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase DropShipSkelMesh;

	UPROPERTY(DefaultComponent, Attach = DropShipSkelMesh, AttachSocket = Base)
	UStaticMeshComponent DropShip;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	USceneComponent MioLocation;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	USceneComponent ZoeLocation;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	UWidgetComponent HackingWidget;
	default HackingWidget.ManuallyRedraw = true;
	default HackingWidget.TickWhenOffscreen = true;
	default HackingWidget.RelativeLocation = FVector(0, 0, 99999999);

	UPROPERTY()
	FOnFirstHackComplete DoneFirstHack;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	UHazeCameraComponent LookUpCam;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	UHazeCameraComponent HackCam;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	UHazeCameraComponent HackCamFirstHack;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor TrasherCam;

	UPROPERTY(EditAnywhere)
	ASpaceWalkEscapeDropshipFinal EscapeShip;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SwipeRightFF;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SwipeLeftFF;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SwipeConfirmFF;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY(EditAnywhere)
	UHazeCameraViewPointBlendType TrasherCamSettings;

	bool bInTransition;

	UPROPERTY()
	FonHackComplete HackingDone;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	UHazeMovablePlayerTriggerComponent EnterTrigger;

	FHazePointOfInterestFocusTargetInfo FocusTarget;

	float ShipProgression;

	// UPROPERTY(EditAnywhere)
	// ASplineActor SplineActor;

	// UHazeSplineComponent Spline;
	
	FHazeTimeLike ShipMovement;
	default ShipMovement.Duration = 70.0;
	default ShipMovement.UseLinearCurveZeroToOne();
	default ShipMovement.bCurveUseNormalizedTime = true;

	bool bBlockCameraMoving = true;

	UPROPERTY()
	FOnBothPlayersHacking BothPlayersHacking;

	UPROPERTY()
	FOnGameOver StartGameOver;

	FRotator LocalRotation;

	FVector DropShipStart;
	FVector DropShipExit;

	FRotator DropShipStartRotation;
	FRotator DropShipExitRotation;

	TPerPlayer<bool> HasEntered;
	bool bHackingLockedIn = false;
	bool bAnimatingCamera = false;
	bool bManualStart = false;
	bool bStartedSecondPhase = false;

	UPROPERTY(DefaultComponent, Attach = DropShip)
	UBillboardComponent CameraTarget;

	FVector TargetCamera;

	FVector StartCamera;

	UPROPERTY()
	FVector Target;

	UPROPERTY()
	FVector Start;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CompRequest; 

	bool bHackingAllowed;

	UPROPERTY()
	int StageIndex = 0;

	TPerPlayer<FSpaceWalkHackingPlayerState> PlayerState;
	
	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveCamera;
	default MoveCamera.Duration = 1.0;
	default MoveCamera.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike TransitionEffect;
	default TransitionEffect.Duration = 0.2;
	default TransitionEffect.UseLinearCurveOneToZero();

	private bool bStartedHacking = false;

	const float ActivateShapeDuration = 0.5;
	const float DeactivateShapeDuration = 0.5;
	const float LockInWindowDuration = 0.25;

	UPROPERTY(EditAnywhere)
	bool bInCutscene;

	UPROPERTY(EditAnywhere)
	bool bIsFinalSection;

	private bool bAppliedRenderTarget = false;

	UPROPERTY()
	FOnPlayerInteractingLastShuttle OnPlayerInteractLastShuttle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnterTrigger.DisableTrigger(this);

		// Spline = SplineActor.Spline;

		EnterTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEntered");

	//	LocalRotation = FRotator(2,1,5);

		ShipMovement.BindUpdate(this , n"ShipMoving");
		ShipMovement.BindFinished(this, n"OnFinishedShipMoving");

		MoveCamera.BindUpdate(this, n"MoveCameraUp");
		MoveCamera.BindFinished(this, n"MoveCameraDown");

		TransitionEffect.BindUpdate(this, n"TransitionUpdate");

		TargetCamera = CameraTarget.RelativeLocation;
		StartCamera = HackCam.RelativeLocation;

		SetLockedHackingText();
		SetActiveIndicators(0);
	}

	void SetLockedHackingText()
	{
		SetHackingText(NSLOCTEXT("SpaceWalkHacking", "Locked", "LOCKED"));
	}

	void SetProcessingHackingText()
	{
		SetHackingText(NSLOCTEXT("SpaceWalkHacking", "Processing", "Processing..."));
	}

	void SetUnlockedHackingText()
	{
		SetHackingText(NSLOCTEXT("SpaceWalkHacking", "AccessGranted", "ACCESS GRANTED"));
	}

	void SetActiveIndicators(int Count)
	{
		FLinearColor ActiveColor = FLinearColor(0.0, 0.2, 0.0);
		FLinearColor InactiveColor = FLinearColor(0.1, 0.0, 0.0);

		USpaceWalkHackingWidget Widget = Cast<USpaceWalkHackingWidget>(HackingWidget.GetWidget());
		Widget.Indicator1.CircleColor = Count >= 1 ? ActiveColor : InactiveColor;
		Widget.Indicator1.RefreshParameters();
		Widget.Indicator2.CircleColor = Count >= 2 ? ActiveColor : InactiveColor;
		Widget.Indicator2.RefreshParameters();
		Widget.Indicator3.CircleColor = Count >= 3 ? ActiveColor : InactiveColor;
		Widget.Indicator3.RefreshParameters();
		Widget.Indicator4.CircleColor = Count >= 4 ? ActiveColor : InactiveColor;
		Widget.Indicator4.RefreshParameters();
		HackingWidget.RequestRenderUpdate();
	}

	void SetHackingText(FText Text)
	{
		USpaceWalkHackingWidget Widget = Cast<USpaceWalkHackingWidget>(HackingWidget.GetWidget());
		Widget.HackingText.SetText(Text);
		HackingWidget.RequestRenderUpdate();
	}

	UFUNCTION(BlueprintEvent)
	void StartAnimation(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION()
	private void OnPlayerEntered(AHazePlayerCharacter Player)
	{
		if (Player.HasControl() && !HasEntered[Player] && !bStartedHacking)
		{
			CrumbPlayerEntered(Player);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlayerEntered(AHazePlayerCharacter Player)
	{
		HasEntered[Player] = true;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		USpaceWalkInteractionEventHandler::Trigger_Start(this, FSpaceWalkInteractionEventHandlerData(Player));

		USceneComponent TargetPoint;
		if (Player.IsMio())
			TargetPoint = MioLocation;
		else
			TargetPoint = ZoeLocation;

		Player.RootOffsetComponent.FreezeRelativeTransformAndLerpBackToParent(this, TargetPoint, 1.0);
		Player.AttachToComponent(TargetPoint, AttachmentRule = EAttachmentRule::SnapToTarget);

		StartAnimation(Player);

		OnPlayerInteractLastShuttle.Broadcast(Player);
	}

	UFUNCTION()
	private void OnFinishedShipMoving()
	{
		LocalRotation = FRotator(0,0,0);
	}

	UFUNCTION(BlueprintCallable)
	void StartShip(bool bSecondPhase = false)
	{
		DropShipStart = DropShip.WorldLocation;
		DropShipExit = DropShipLocation.ActorLocation;

		DropShipStartRotation = DropShip.WorldRotation;
		DropShipExitRotation = DropShipLocation.ActorRotation;

		EnterTrigger.EnableTrigger(this);

		ShipMovement.PlayFromStart();
		bStartedSecondPhase = bSecondPhase;

		if (bSecondPhase)
		{
			SetActiveIndicators(1);

			PlayerState[EHazePlayer::Mio].ShapeIndex = 5;
			PlayerState[EHazePlayer::Zoe].ShapeIndex = 5;
			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook1_Index", PlayerState[EHazePlayer::Mio].ShapeIndex);
			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook2_Index", PlayerState[EHazePlayer::Zoe].ShapeIndex);
		}
	}

	UFUNCTION()
	void StopShip()
	{
		ShipMovement.SetPlayRate(0.0);
	}


	UFUNCTION()
	private void ShipMoving(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(DropShipStart,DropShipExit, CurrentValue));
		SetActorRotation(Math::LerpShortestPath(DropShipStartRotation, DropShipExitRotation, CurrentValue));

		ShipProgression = CurrentValue;
	}


	UFUNCTION()
	void TriggerGameOver()
	{
		StartGameOver.Broadcast();
		Game::Mio.ActivateCamera(TrasherCam, 5.0, this);
	}

	UFUNCTION()
	void StartHack()
	{
		bStartedHacking = true;
		BothPlayersHacking.Broadcast();
	}

	UFUNCTION()
	private void MoveCameraDown()
	{

	}

	UFUNCTION()
	private void TransitionUpdate(float CurrentValue)
	{
	}

	UFUNCTION()
	private void MoveCameraUp(float CurrentValue)
	{
		HackCam.SetRelativeLocation(Math::Lerp(StartCamera, TargetCamera, CurrentValue));
	}

	bool IsCorrectShapeIndex(AHazePlayerCharacter Player, int ShapeIndex)
	{
		switch(StageIndex)
		{
			case 0:
				return ShapeIndex == 4;
			case 1:
				return ShapeIndex == 9;
			case 2:
				return ShapeIndex == 14;
			case 3:
				return ShapeIndex == 19;
		}

		return false;
	}

	UFUNCTION()
	private void GetNewShape()
	{
		bInTransition = true;
		bAnimatingCamera = true;
		SetProcessingHackingText();
		DropShip.SetScalarParameterValueOnMaterials(n"Flipbook1_Intensity", 0);
		DropShip.SetScalarParameterValueOnMaterials(n"Flipbook2_Intensity", 0);
		DropShip.SetScalarParameterValueOnMaterials(n"Flipbook3_Intensity", 0);
		DropShip.SetScalarParameterValueOnMaterials(n"TearInterval", 0.6);
		DropShip.SetScalarParameterValueOnMaterials(n"TearLength", 1.0);
		DropShip.SetScalarParameterValueOnMaterials(n"ScreenWobble_Speed", 1.0);
		DropShip.SetScalarParameterValueOnMaterials(n"ScreenWobble_Speed", 1.0);
		DropShip.SetScalarParameterValueOnMaterials(n"Scanline_2_Speed", 2.0);
		DropShip.SetScalarParameterValueOnMaterials(n"Scanline_1_Speed", 2.0);
		DropShip.SetScalarParameterValueOnMaterials(n"Scanline_2_Str", 2.0);
		DropShip.SetScalarParameterValueOnMaterials(n"Scanline_1_Str", 2.0);
		DropShip.SetVectorParameterValueOnMaterials(n"MaskB_Color", FVector(0.413541,0.220325,0.039071));
		DropShip.SetVectorParameterValueOnMaterials(n"MaskG_Color", FVector(0.413541,0.220325,0.039071));
		DropShip.SetVectorParameterValueOnMaterials(n"MaskR_Color", FVector(0.413541,0.220325,0.039071));
		USpaceWalkInteractionEventHandler::Trigger_Scramble(this);

		Timer::SetTimer(this, n"Transition", 1.0);
	//	if(!bBlockCameraMoving)
		//	Game::Mio.ActivateCamera(LookUpCam, 3.0,this);
	}

	UFUNCTION()
	private void Transition()
	{
		Timer::SetTimer(this, n"NextStage", 1.0);

		DeactivateSymbols();
		bAnimatingCamera = false;
	}

	UFUNCTION()
	void Finished()
	{
		bAnimatingCamera = true;
		SetUnlockedHackingText();
		Timer::SetTimer(this, n"FinalCutscene", 1.0);
	}

	UFUNCTION()
	void FinalCutscene()
	{
		DeactivateSymbols();
		bAnimatingCamera = false;
		HackingDone.Broadcast();


		HasEntered[Game::Mio] = false;
		HasEntered[Game::Zoe] = false;
	}

	UFUNCTION()
	void NextStage()
	{

		// if(!bBlockCameraMoving)
		// 	Game::Mio.ActivateCamera(HackCam, 3.0,this);

		bInTransition = false;

		DropShip.SetScalarParameterValueOnMaterials(n"Flipbook1_Intensity", 1);
		DropShip.SetScalarParameterValueOnMaterials(n"Flipbook2_Intensity", 1);
		DropShip.SetScalarParameterValueOnMaterials(n"Flipbook3_Intensity", 1);
		DropShip.SetScalarParameterValueOnMaterials(n"TearInterval", 1.05);
		DropShip.SetScalarParameterValueOnMaterials(n"TearLength", 0.02);
		DropShip.SetScalarParameterValueOnMaterials(n"ScreenWobble_Speed", 0.0);
		DropShip.SetScalarParameterValueOnMaterials(n"ScreenWobble_Speed", 0.0);
		DropShip.SetScalarParameterValueOnMaterials(n"Scanline_2_Speed", 0.1);
		DropShip.SetScalarParameterValueOnMaterials(n"Scanline_1_Speed", 0.1);
		DropShip.SetScalarParameterValueOnMaterials(n"Scanline_2_Str", 1.2);
		DropShip.SetScalarParameterValueOnMaterials(n"Scanline_1_Str", 0.2);
		DropShip.SetVectorParameterValueOnMaterials(n"MaskB_Color", FVector(0.05098,0.015994,0.002098));
		DropShip.SetVectorParameterValueOnMaterials(n"MaskG_Color", FVector(0.057292,0.019127,0.0));
		DropShip.SetVectorParameterValueOnMaterials(n"MaskR_Color", FVector(0.114583,0.06093,0.041297));

		StageIndex += 1;
		USpaceWalkInteractionEventHandler::Trigger_Progress(this,FSpaceWalkInteractionEventHandlerDataProgress(StageIndex));
		switch(StageIndex)
		{
			case 1:
			PlayerState[EHazePlayer::Mio].ShapeIndex = 5;
			PlayerState[EHazePlayer::Zoe].ShapeIndex = 5;
			SetLockedHackingText();
			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook3_Index", 2);
			break;

			case 2:
			PlayerState[EHazePlayer::Mio].ShapeIndex = 10;
			PlayerState[EHazePlayer::Zoe].ShapeIndex = 10;
			SetLockedHackingText();
			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook3_Index", 3);
			break;

			case 3: 
			PlayerState[EHazePlayer::Mio].ShapeIndex = 15;
			PlayerState[EHazePlayer::Zoe].ShapeIndex = 15;
			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook3_Index", 4);
			SetLockedHackingText();
			break;

			case 4:
			PlayerState[EHazePlayer::Mio].ShapeIndex = 20;
			PlayerState[EHazePlayer::Zoe].ShapeIndex = 20;
			SetUnlockedHackingText();
			break;
		}

		DropShip.SetScalarParameterValueOnMaterials(n"FlipBook1_Index", PlayerState[EHazePlayer::Mio].ShapeIndex);
		DropShip.SetScalarParameterValueOnMaterials(n"FlipBook2_Index", PlayerState[EHazePlayer::Zoe].ShapeIndex);
	}

	UFUNCTION(BlueprintCallable)
	void ManualStart()
	{
		bManualStart = true;
		HackingStarted();
		bHackingAllowed = true;
		BothHacking();

		HasEntered[Game::Mio] = true;
		HasEntered[Game::Zoe] = true;
	}

	UFUNCTION(BlueprintCallable)
	void SecondStart()
	{
		ShipMovement.SetPlayRate(0.5);
		bBlockCameraMoving = false;
		Game::Mio.ActivateCamera(LookUpCam, 4.5,this);
		Game::Mio.ApplyViewSizeOverride(this,EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
		StageIndex = 1;
		SetActiveIndicators(1);
		DropShip.SetScalarParameterValueOnMaterials(n"FlipBook3_Index", 2);
		Timer::SetTimer(this, n"RenderUI", 3.5);
		Timer::SetTimer(this, n"ResumeHacking", 4.0);
	//	ResumeHacking();

		PlayerState[EHazePlayer::Mio].ShapeIndex = 5;
		PlayerState[EHazePlayer::Zoe].ShapeIndex = 5;
		DropShip.SetScalarParameterValueOnMaterials(n"FlipBook1_Index", PlayerState[EHazePlayer::Mio].ShapeIndex);
		DropShip.SetScalarParameterValueOnMaterials(n"FlipBook2_Index", PlayerState[EHazePlayer::Zoe].ShapeIndex);
	}

	UFUNCTION()
	private void ResumeHacking()
	{
		HackingStarted();
		BothHackingFinal();
		ShipMovement.SetPlayRate(1.0);
		Game::Mio.ActivateCamera(HackCam, 2.0,this);
		bHackingAllowed = true;

	}

	UFUNCTION()
	private void HackingStarted()
	{
		bHackingAllowed = true;
		CompRequest.StartInitialSheetsAndCapabilities(Game::Mio, this);
		CompRequest.StartInitialSheetsAndCapabilities(Game::Zoe, this);
	}

	UFUNCTION(BlueprintCallable)
	void FinishHack()
	{
		HackingDone.Broadcast();
		ShipMovement.SetPlayRate(0.0);
	}

	bool CanPlayerUseInput(AHazePlayerCharacter Player)
	{
		return bHackingAllowed && !PlayerState[Player].bActivated && !PlayerState[Player].bDeactivated && !bHackingLockedIn;
	}

	UFUNCTION()
	void ActionLeftMio()
	{
		if (CanPlayerUseInput(Game::Mio))
		{
			USpaceWalkInteractionEventHandler::Trigger_SwipeLeft(this, FSpaceWalkInteractionEventHandlerData(Game::Mio));
			Game::Mio.PlayForceFeedback(SwipeLeftFF,false,false,this);
			int& IndexMio = PlayerState[EHazePlayer::Mio].ShapeIndex;
			switch(StageIndex)
			{
				case 0:
				IndexMio += 1;
				if(IndexMio > 5)
					IndexMio = 0;
				break;

				case 1:
				IndexMio += 1;
				if(IndexMio > 10)
					IndexMio = 5;
				break;

				case 2:
				IndexMio += 1;
				if(IndexMio > 15)
					IndexMio = 10;
				break;

				case 3:
				IndexMio += 1;
				if(IndexMio > 20)
					IndexMio = 15;
				break;
			}
			
			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook1_Index", IndexMio);
		}
	}

	UFUNCTION()
	void ActionRightMio()
	{
		if (CanPlayerUseInput(Game::Mio))
		{
			USpaceWalkInteractionEventHandler::Trigger_SwipeRight(this, FSpaceWalkInteractionEventHandlerData(Game::Mio));
			Game::Mio.PlayForceFeedback(SwipeRightFF,false,false,this);
			int& IndexMio = PlayerState[EHazePlayer::Mio].ShapeIndex;
			switch(StageIndex)
			{
				case 0:
				IndexMio -= 1;
				if(IndexMio < 0)
					IndexMio = 5;
				break;

				case 1:
				IndexMio -= 1;
				if(IndexMio < 5)
					IndexMio = 10;
				break;

				case 2:
				IndexMio -= 1;
				if(IndexMio < 10)
					IndexMio = 15;
				break;

				case 3:
				IndexMio -= 1;
				if(IndexMio < 15)
					IndexMio = 20;
				break;
			}

			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook1_Index", IndexMio);
		}
	}

	UFUNCTION()
	void ActionRightZoe()
	{
		if (CanPlayerUseInput(Game::Zoe))
		{
			USpaceWalkInteractionEventHandler::Trigger_SwipeLeft(this, FSpaceWalkInteractionEventHandlerData(Game::Zoe));
			Game::Zoe.PlayForceFeedback(SwipeRightFF,false,false,this);
			int& IndexZoe = PlayerState[EHazePlayer::Zoe].ShapeIndex;
			switch(StageIndex)
			{
				case 0:
				IndexZoe += 1;
				if(IndexZoe > 4)
					IndexZoe = 0;
				break;

				case 1:
				IndexZoe += 1;
				if(IndexZoe > 9)
					IndexZoe = 5;
				break;

				case 2:
				IndexZoe += 1;
				if(IndexZoe > 15)
					IndexZoe = 10;
				break;

				case 3:
				IndexZoe += 1;
				if(IndexZoe > 19)
					IndexZoe = 15;
				break;

			}

			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook2_Index", IndexZoe);
		}
	}

	UFUNCTION()
	void ActionLeftZoe()
	{
		if (CanPlayerUseInput(Game::Zoe))
		{
			USpaceWalkInteractionEventHandler::Trigger_SwipeRight(this, FSpaceWalkInteractionEventHandlerData(Game::Zoe));
			Game::Zoe.PlayForceFeedback(SwipeLeftFF,false,false,this);
			int& IndexZoe = PlayerState[EHazePlayer::Zoe].ShapeIndex;
			switch(StageIndex)
			{
				case 0:
				IndexZoe -= 1;
				if(IndexZoe < 0)
					IndexZoe = 4;
				break;

				case 1:
				IndexZoe -= 1;
				if(IndexZoe < 5)
					IndexZoe = 9;
				break;

				case 2:
				IndexZoe -= 1;
				if(IndexZoe < 10)
					IndexZoe = 15;
				break;

				case 3:
				IndexZoe -= 1;
				if(IndexZoe < 15)
					IndexZoe = 19;
				break;
			}

			DropShip.SetScalarParameterValueOnMaterials(n"FlipBook2_Index", IndexZoe);
		}
	}


	void ActivateShape(AHazePlayerCharacter Player)
	{
		FSpaceWalkHackingPlayerState& State = PlayerState[Player];
		State.bActivated = true;
		State.Timer = 0.0;
		SetFlipbookIntensity(Player, 10.0);
		Player.PlayForceFeedback(SwipeConfirmFF, false, false, this);
		USpaceWalkInteractionEventHandler::Trigger_Press(this, FSpaceWalkInteractionEventHandlerData(Player));
		USpaceWalkInteractionEventHandler::Trigger_UIMoveIn(this, FSpaceWalkInteractionEventHandlerData(Player));
	}

	void SetFlipbookIntensity(AHazePlayerCharacter Player, float Intensity)
	{
		if (Player.IsMio())
			{
			DropShip.SetScalarParameterValueOnMaterials(n"Flipbook1_Intensity", Intensity);
			}
		else
		{
			DropShip.SetScalarParameterValueOnMaterials(n"Flipbook2_Intensity", Intensity);
		}

	}

	void SetFlipbookPosition(AHazePlayerCharacter Player, float Position)
	{
		if (Player.IsMio())
			DropShip.SetScalarParameterValueOnMaterials(n"Flipbook1_Pos_X(-1-+1)", Math::Lerp(1.842971, 0, Position));
		else
			DropShip.SetScalarParameterValueOnMaterials(n"Flipbook2_Pos_X(-1-+1)", Math::Lerp(-1.842971, 0, Position));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bAppliedRenderTarget && HackingWidget.GetRenderTarget() != nullptr)
		{
			DropShip.SetTextureParameterValueOnMaterials(n"Widget", HackingWidget.GetRenderTarget());
			bAppliedRenderTarget = true;
		}

		if (ShipProgression >= 0.95 && !bInCutscene)
			TriggerGameOver();

		if (HasEntered[EHazePlayer::Mio] && HasEntered[EHazePlayer::Zoe] && !bManualStart)
		{
			if (!bStartedHacking)
				StartHack();
		}

		if (bHackingAllowed)
		{
			if (bHackingLockedIn)
			{
				bool bBothPlayersCentered = true;
				for (auto Player : Game::Players)
				{
					// Update trying out the shape
					FSpaceWalkHackingPlayerState& State = PlayerState[Player];
					if (State.Timer < ActivateShapeDuration + LockInWindowDuration)
						bBothPlayersCentered = false;
					if (State.bRequestedDeactivation)
						bBothPlayersCentered = false;
				}

				if (bBothPlayersCentered)
				{
					TEMPORAL_LOG(this).Event(f"Hacking Stage Completed");

					USpaceWalkHackingEffectHandler::Trigger_ShapeFilled(this);

					bHackingLockedIn = false;
					SetActiveIndicators(StageIndex+1);

					if (StageIndex == 0)
					{
						StopHacking();
					}
					else if (StageIndex == 3)
						Finished();
					else
						GetNewShape();
				}
			}

			// Update the positioning for the symbols
			for (auto Player : Game::Players)
			{
				// Update trying out the shape
				FSpaceWalkHackingPlayerState& State = PlayerState[Player];
				if (State.bActivated)
				{
					State.Timer += DeltaSeconds;

					float Alpha = Math::Saturate(State.Timer / ActivateShapeDuration);
					SetFlipbookPosition(Player, Math::EaseInOut(0, 1, Alpha, 2));

					if (State.Timer > ActivateShapeDuration + LockInWindowDuration)
					{
						if (!State.bRequestedDeactivation && !bAnimatingCamera && !bHackingLockedIn && !State.bDeactivated && Player.HasControl())
						{
							State.bRequestedDeactivation = true;
							NetRequestDeactivation(Player);
						}
					}
				}
				else if (State.bDeactivated)
				{
					State.Timer += DeltaSeconds;

					float Alpha = Math::Saturate(State.Timer / DeactivateShapeDuration);
					SetFlipbookPosition(Player, Math::EaseInOut(1, 0, Alpha, 2));

					if (State.Timer > DeactivateShapeDuration)
					{
						State.bActivated = false;
						State.bDeactivated = false;
						State.bRequestedDeactivation = false;
						State.Timer = 0.0;

						if(!bInTransition)
						{
							SetFlipbookPosition(Player, 0.0);
							SetFlipbookIntensity(Player, 1.0);
						}
						
					}
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetRequestDeactivation(AHazePlayerCharacter Player)
	{
		if (!Network::IsGameNetworked() || !Player.HasControl())
		{
			TEMPORAL_LOG(this).Event(f"NetRequestDeactivation {Player.Player :n}");

			// See if we should lock in or finish the hacking
			bool bBothPlayersCorrect = true;
			for (auto CheckPlayer : Game::Players)
			{
				// Update trying out the shape
				FSpaceWalkHackingPlayerState& State = PlayerState[CheckPlayer];
				if (!State.bActivated || State.bDeactivated || !IsCorrectShapeIndex(CheckPlayer, State.ShapeIndex))
				{
					bBothPlayersCorrect = false;
					USpaceWalkInteractionEventHandler::Trigger_UIMoveOut(this, FSpaceWalkInteractionEventHandlerData(Player));
				}
			}

			if (bBothPlayersCorrect)
			{
				NetRespondLockIn(Player);
			}
			else
			{
				NetRespondDeactivation(Player);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetRespondDeactivation(AHazePlayerCharacter Player)
	{
		FSpaceWalkHackingPlayerState& State = PlayerState[Player];
		State.bRequestedDeactivation = false;

		if (!bHackingLockedIn)
		{
			State.bActivated = false;
			State.bDeactivated = true;
			State.Timer = 0.0;

			USpaceWalkInteractionEventHandler::Trigger_UIFail(this);
		}

		TEMPORAL_LOG(this).Event(f"NetRespondDeactivation {Player.Player :n} locked in {bHackingLockedIn}");
	}

	UFUNCTION(NetFunction)
	private void NetRespondLockIn(AHazePlayerCharacter Player)
	{
		FSpaceWalkHackingPlayerState& State = PlayerState[Player];
		State.bRequestedDeactivation = false;

		bHackingLockedIn = true;
		USpaceWalkInteractionEventHandler::Trigger_UISuccess(this);

		for (auto CheckPlayer : Game::Players)
		{
			FSpaceWalkHackingPlayerState& CheckState = PlayerState[CheckPlayer];
			State.bActivated = true;
			State.bDeactivated = false;
		}

		TEMPORAL_LOG(this).Event(f"NetRespondLockIn {Player.Player :n}");
	}

	UFUNCTION()
	private void GameOver()
	{
		DontShowUI();
	}

	UFUNCTION()
	private void BothHackingFinal()
	{
		ApplyHackCamFinal();
	}

	UFUNCTION()
	private void BothHacking()
	{
		RenderUI();
		ApplyHackCam();
	}

	UFUNCTION()
	void StopHacking()
	{
		Timer::SetTimer(this, n"StartCutscene", 5.0);
		GetNewShape();
	}

	UFUNCTION()
	void StartCutscene()
	{
		DoneFirstHack.Broadcast();
		DontShowUI();
		bManualStart = false;
		bHackingAllowed = false;
		bHackingLockedIn = false;
		RemoveCams();

		DeactivateSymbols();

		HasEntered[Game::Mio] = false;
		HasEntered[Game::Zoe] = false;
	}

	void DeactivateSymbols()
	{
		for (auto Player : Game::Players)
		{
			// Update trying out the shape
			FSpaceWalkHackingPlayerState& State = PlayerState[Player];
			State.bActivated = false;
			State.bDeactivated = true;
			State.Timer = 0.0;
		}
	}

	UFUNCTION(BlueprintEvent)
	void RenderUI()
	{

	}

	UFUNCTION(BlueprintEvent)
	void DontShowUI()
	{
		
	}

	UFUNCTION(BlueprintCallable)
	void ApplyHackCamFinal()
	{

	//	Timer::SetTimer(this, n"ReverseCameraShot", 1.0);
	//	HackCam.RelativeLocation = CameraTarget.RelativeLocation;
	//	MoveCamera.ReverseFromEnd();

		UHazeCameraComponent Camera = HackCam;
		Game::Mio.ActivateCamera(Camera, 4.0, this);	
	}

	UFUNCTION()
	void ReverseCameraShot()
	{
		MoveCamera.ReverseFromEnd();
	}

	UFUNCTION(BlueprintCallable)
	void ApplyHackCam()
	{
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
		UHazeCameraComponent Camera = HackCamFirstHack;
		Game::Mio.ActivateCamera(Camera, 2.0, this);
	}

	UFUNCTION()
	void RemoveCams()
	{
		Game::Mio.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
		Game::Mio.DeactivateCameraByInstigator(this, 4.0);
	}
};

UCLASS(Abstract)
class USpaceWalkHackingWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTextBlock HackingText;

	UPROPERTY(BindWidget)
	URadialProgressWidget Indicator1;
	UPROPERTY(BindWidget)
	URadialProgressWidget Indicator2;
	UPROPERTY(BindWidget)
	URadialProgressWidget Indicator3;
	UPROPERTY(BindWidget)
	URadialProgressWidget Indicator4;
}