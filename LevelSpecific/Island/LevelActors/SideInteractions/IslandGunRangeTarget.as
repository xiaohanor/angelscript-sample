event void FAIslandGunRangeTargetSignature();

class AIslandGunRangeTarget : AHazeActor
{
	
	UPROPERTY()
	FAIslandGunRangeTargetSignature OnImpact;
	UPROPERTY()
	FAIslandGunRangeTargetSignature OnActivated;
	UPROPERTY()
	FAIslandGunRangeTargetSignature OnDead;
	UPROPERTY()
	FAIslandGunRangeTargetSignature OnReachedDestination;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SideDestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HeadTargetMesh;

	UPROPERTY(DefaultComponent, Attach = HeadTargetMesh)
	UIslandRedBlueImpactCounterResponseComponent RedBlueHeadTargetComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BodyTargetMesh;

	UPROPERTY(DefaultComponent, Attach = BodyTargetMesh)
	UIslandRedBlueImpactCounterResponseComponent RedBlueBodyTargetComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase ZoeSkelMesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditAnywhere)
	EIslandRedBlueWeaponType BlockColor;

	UPROPERTY(EditInstanceOnly)
	AIslandGunRangeScoreCount ScoreCountRef;

	UPROPERTY(EditInstanceOnly)
	bool bUseRelativeLocation;

	UPROPERTY(EditInstanceOnly)
	bool bAutoActivate;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerRef;

	UPROPERTY()
	UForceFeedbackEffect HeadShotFeedback;

	UPROPERTY()
	UForceFeedbackEffect BodyShotFeedback;

	UPROPERTY()
	UForceFeedbackEffect FailedShotFeedback;

	bool bIsActive;

	UPROPERTY()
	UAnimSequence Idle;
	UPROPERTY()
	UAnimSequence RoarAnim;
	UPROPERTY()
	UAnimSequence DisableAnim;

	UPROPERTY()
	FHazeTimeLike  PopupAnimation;
	default PopupAnimation.Duration = 0.1;
	default PopupAnimation.UseLinearCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 0.2;
	default MoveAnimation.UseLinearCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike  SidewaysAnimation;
	default SidewaysAnimation.Duration = 1.0;
	default SidewaysAnimation.UseLinearCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	bool bMoveSideways;
	
	UPROPERTY(EditAnywhere)
	float SidewaysDuration = 7.0;

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	FTransform SideStartingTransform;
	FQuat SideStartingRotation;
	FVector SideStartingPosition;
	FTransform SideEndingTransform;
	FQuat SideEndingRotation;
	FVector SideEndingPosition;

	float CurrentAlpha;
	AHazePlayerCharacter LastPlayerImpacter;

	float HeadShotPoints = 50;
	float BodyShotPoints = 25;
	float MinusShotPoints = -25;

	bool bFailedShot;
	bool bSuccessShot;
	bool bHasBeenActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RedBlueHeadTargetComponent.OnImpactEvent.AddUFunction(this, n"HeadImpact");
		RedBlueBodyTargetComponent.OnImpactEvent.AddUFunction(this, n"BodyImpact");

		StartingTransform = Root.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		SideStartingTransform = GetActorTransform();
		SideStartingPosition = SideStartingTransform.GetLocation();
		SideStartingRotation = SideStartingTransform.GetRotation();

		SideEndingTransform = SideDestinationComp.GetWorldTransform();
		SideEndingPosition = SideEndingTransform.GetLocation();
		SideEndingRotation = SideEndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		OnUpdate(1);

		SidewaysAnimation.SetPlayRate(1.0 / SidewaysDuration);
		SidewaysAnimation.BindUpdate(this, n"OnSideUpdate");
		SidewaysAnimation.BindFinished(this, n"OnSideFinished");

		bIsActive = false;

		if (bAutoActivate)
			ActivateTarget();

		if(TriggerRef != nullptr)
			TriggerRef.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (bIsActive)
			return;

		ActivateTarget();
	}

	UFUNCTION()
	void HeadImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!bIsActive)
			return;

		LastPlayerImpacter = Data.Player;
		DestroyTarget();
		bFailedShot = false;
		bSuccessShot = false;

		if (ScoreCountRef != nullptr)
		{

			if(BlockColor == EIslandRedBlueWeaponType::Red && LastPlayerImpacter == Game::GetPlayer(EHazePlayer::Mio))
				bFailedShot = true;

			if(BlockColor == EIslandRedBlueWeaponType::Blue && LastPlayerImpacter == Game::GetPlayer(EHazePlayer::Zoe))
				bFailedShot = true;

			if (bFailedShot)
				FailedShot();

			BP_OnDestroyed(true, bFailedShot);

			if (bFailedShot)
				return;

			if(BlockColor == EIslandRedBlueWeaponType::Blue && LastPlayerImpacter == Game::GetPlayer(EHazePlayer::Mio))
			{
				bSuccessShot = true;
				UIslandGunRangeTargetEventHandler::Trigger_OnRedHeadShot(this);
				// PrintToScreen("Red Head Shot!", 1);
			}
				
			
			if(BlockColor == EIslandRedBlueWeaponType::Red && LastPlayerImpacter == Game::GetPlayer(EHazePlayer::Zoe))
			{
				bSuccessShot = true;
				UIslandGunRangeTargetEventHandler::Trigger_OnBlueHeadShot(this);
				// PrintToScreen("Blue Head Shot!", 1);
			}

			if (bSuccessShot)
				ScoreCountRef.UpdateDisplay(HeadShotPoints);
			
			LastPlayerImpacter.PlayForceFeedback(HeadShotFeedback, false, false, this);

		}
			
	}

	UFUNCTION()
	void BodyImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!bIsActive)
			return;
		
		LastPlayerImpacter = Data.Player;
		DestroyTarget();
		bFailedShot = false;
		bSuccessShot = false;
		
		if (ScoreCountRef != nullptr)
		{

			if(BlockColor == EIslandRedBlueWeaponType::Red && LastPlayerImpacter == Game::GetPlayer(EHazePlayer::Mio))
				bFailedShot = true;
			if(BlockColor == EIslandRedBlueWeaponType::Blue && LastPlayerImpacter == Game::GetPlayer(EHazePlayer::Zoe))
				bFailedShot = true;

			if (bFailedShot)
			{
				FailedShot();
			}

			BP_OnDestroyed(false, bFailedShot);

			if(BlockColor == EIslandRedBlueWeaponType::Blue && LastPlayerImpacter == Game::GetPlayer(EHazePlayer::Mio))
			{
				bSuccessShot = true;
				UIslandGunRangeTargetEventHandler::Trigger_OnRedBodyShot(this);
				// PrintToScreen("Red Body Shot!", 1);
			}
				
			
			if(BlockColor == EIslandRedBlueWeaponType::Red && LastPlayerImpacter == Game::GetPlayer(EHazePlayer::Zoe))
			{
				bSuccessShot = true;
				UIslandGunRangeTargetEventHandler::Trigger_OnRedBodyShot(this);
				// PrintToScreen("Blue Body Shot!", 1);
			}

			if (bSuccessShot)
				ScoreCountRef.UpdateDisplay(BodyShotPoints);

			LastPlayerImpacter.PlayForceFeedback(BodyShotFeedback, false, false, this);

		}

	}

	UFUNCTION()
	void ActivateTarget()
	{
		bIsActive = true;
		bHasBeenActivated = true;
		BP_OnActivated();
		MoveAnimation.ReverseFromEnd();
		PlayDisableAnimation();

		if (bMoveSideways)
			SidewaysAnimation.PlayFromStart();
	}

	UFUNCTION()
	void DeactivateTarget()
	{
		if (!bHasBeenActivated)
			return;

		BP_OnDeactivated();
		MoveAnimation.Play();

		if (bMoveSideways)
		{
			SidewaysAnimation.Stop();
			OnSideUpdate(0);
		}
		
	}

	UFUNCTION()
	void DestroyTarget()
	{
		bIsActive = false;
		PlayRoarAnimation();
	}

	UFUNCTION()
	void FailedShot()
	{
		UIslandGunRangeTargetEventHandler::Trigger_OnFailedShot(this);
		// PrintToScreen("Failed shot", 1);
		ScoreCountRef.UpdateDisplay(MinusShotPoints);
		LastPlayerImpacter.PlayForceFeedback(FailedShotFeedback, false, false, this);
		BP_OnFailedShot();
	}

	UFUNCTION()
	void PlayIdleAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = Idle;
		Params.BlendTime = 0.5;
		Params.bLoop = false;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
		ZoeSkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

	UFUNCTION()
	void PlayRoarAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = RoarAnim;
		Params.BlendTime = 0.15;
		Params.bLoop = false;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
		ZoeSkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

	UFUNCTION()
	void PlayDisableAnimation()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = DisableAnim;
		Params.BlendTime = 0.5;
		Params.bLoop = true;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
		ZoeSkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);	
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		Root.SetRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		Root.SetRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		PlayIdleAnimation();
	}

	UFUNCTION()
	void OnSideUpdate(float Alpha)
	{
		SetActorLocation(Math::Lerp(SideStartingPosition, SideEndingPosition, Alpha));
	}

	UFUNCTION()
	void OnSideFinished()
	{
		if (!bIsActive)
			return;

		if (!SidewaysAnimation.IsReversed())
			SidewaysAnimation.ReverseFromEnd();
		else
			SidewaysAnimation.PlayFromStart();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDestroyed(bool bHeadshot, bool bFailed) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnFailedShot() {}

}