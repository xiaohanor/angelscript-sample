event void FEventTotemHeightChanged();
event void FEventTotemFacingChanged();
event void FTotemPuzzleEvent();
event void FLockTotem();
event void FCorrectTotemLocked();
event void FUnlockTotem();
event void FTargetTotem();
event void FUntargetTotem();

enum ETundraTotemIndex
{
	NONE = - 1,
	Left = 0,
	Middle = 1,
	Right = 2
}

enum ETundraTotemFacing
{
	Front,
	Back
}

class ATundra_River_TotemPuzzle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SinkRoot;

	UPROPERTY(DefaultComponent, Attach = SinkRoot)
	UNiagaraComponent LeftEyeActivationComp;

	UPROPERTY(DefaultComponent, Attach = SinkRoot)
	UNiagaraComponent RightEyeActivationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCameraShakeForceFeedbackComponent MoveCamShakeFFComp;

	UPROPERTY()
	FEventTotemHeightChanged TotemHeightChanged;

	UPROPERTY()
	FEventTotemFacingChanged TotemFacingChanged;

	UPROPERTY()
	FTotemPuzzleEvent PuzzleSolved;

	UPROPERTY()
	FTotemPuzzleEvent PuzzleNotSolved;

	UPROPERTY()
	FTotemPuzzleEvent FirstPuzzleSolved;

	UPROPERTY()
	FTargetTotem OnTotemTargeted;

	UPROPERTY()
	FUntargetTotem OnTotemUntargeted;

	UPROPERTY()
	FCorrectTotemLocked OnCorrectTotemLocked;

	// UPROPERTY()
	// FLockTotem LockTotem;

	// UPROPERTY()
	// FUnlockTotem UnlockTotem;

	UPROPERTY(EditInstanceOnly)
	ETundraTotemIndex TotemIndex = ETundraTotemIndex::NONE;

	UPROPERTY(EditDefaultsOnly)
	int StartTargetHeight = 3;

	UPROPERTY(EditDefaultsOnly)
	ETundraTotemFacing StartFacing = ETundraTotemFacing::Front;

	UPROPERTY(EditInstanceOnly)
	int FirstSolutionHeight;

	UPROPERTY(EditInstanceOnly)
	int SecondSolutionHeight;
	
	UPROPERTY(EditDefaultsOnly)
	float MoveUpTime = 2.25;
	
	UPROPERTY(EditAnywhere)
	float NextStageDelay = 2;

	UPROPERTY(EditAnywhere)
	float LockDuration = 5;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ZoeSlamFF;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ShakeFF;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect RotateFF;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem RootsUnlockEfect;

	UPROPERTY(BlueprintReadOnly)
	bool bLastInputWasAGroundSlam;

	UPROPERTY()
	bool bPuzzleSolved;

	UPROPERTY(BlueprintReadOnly)
	float SlamCooldown = -1;

	UPROPERTY(BlueprintReadOnly)
	bool bSlammable = true;

	UPROPERTY()
	bool bIsLocked = false;

	UPROPERTY(BlueprintReadOnly)
	bool bIsTargeted = false;
	
	UPROPERTY(BlueprintReadOnly)
	bool bMoveShake = false;

	UPROPERTY(BlueprintReadOnly)
	float TargetRotation;
	
	UPROPERTY(BlueprintReadOnly)
	int SolutionHeight;

	UPROPERTY(BlueprintReadOnly)
	ETundraTotemFacing SolutionFacing = ETundraTotemFacing::Front;

	float CurrentLockDuration = LockDuration;
	float MaxSlamCooldown = 0.5;
	float TimeLastMovedUp;
	float TimeLastLocked;
	float TimeNextUnlock;
	float TimeSolved;
	bool bEyesActive = false;
	

	UPROPERTY()
	int TargetHeight;
	
	ETundraTotemFacing CurrentFacing = ETundraTotemFacing::Front;

	UPROPERTY()
	ATundra_River_TotemPuzzle_TreeControl TreeControl;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent SlamComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		TargetHeight = StartTargetHeight;
		// SetTargetFacing(StartFacing);
		SlamComp.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		BP_ToggleTargetedMeshes(false);
		SolutionHeight = FirstSolutionHeight;
	}

	// UFUNCTION()
	// private void OnTotemRaised(ATundra_River_TotemPuzzle RaisedTotem)
	// {
	// 	if(RaisedTotem != this)
	// 		return;

	// 	BP_TotemRaised();
	// }

	UFUNCTION()
	void TreeControlSetup()
	{
		// TreeControl.TotemRaised.AddUFunction(this, n"OnTotemRaised");
	}

	UFUNCTION(BlueprintCallable)
	void BP_SetLockedStatus(bool bLock)
	{
		bIsLocked = bLock;
	}

	UFUNCTION()
	void LockTotem()
	{
		if(TargetHeight == SolutionHeight)
		{
			TimeLastLocked = Time::GetGameTimeSeconds();
			CurrentLockDuration = LockDuration;
			OnCorrectTotemLocked.Broadcast();
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_CorrectTotemLocked(this);
			ToggleEyes(true);
		}
		else
		{
			TimeLastLocked = Time::GetGameTimeSeconds();
			CurrentLockDuration = LockDuration * 0.5;
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_TotemLocked(this);
		}

		TimeNextUnlock = TimeLastLocked + CurrentLockDuration;
		bMoveShake = false;
		Game::GetMio().StopForceFeedback(this);

		BP_LockTotem();
		TreeControl.SolutionCheck();
	}

	UFUNCTION()
	void UnlockTotem()
	{
		UTundra_River_TotemPuzzle_EffectHandler::Trigger_TotemUnlocked(this);
		ToggleEyes(false);
		BP_UnlockTotem();
		if(!bPuzzleSolved)
			TreeControl.SolutionCheck();
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType,
	                          FVector PlayerLocation)
	{	
		if(Game::Mio.HasControl())
			NetGroundSlam();
	}

	UFUNCTION(NetFunction)
	private void NetGroundSlam()
	{
		if(bSlammable && !bIsLocked && !bPuzzleSolved /*&& !TreeControl.GetOppositeTotem(this).IsAtMaxHeight()*/)
		{
			if(TargetHeight > 0)
			{
				SetTargetHeight(0, true);
				ResetMoveUpTime();
				// TreeControl.OppositeTotemReaction(this);
				// SwapTargetFacing();
				// TreeControl.GetOppositeTotem(this).SwapTargetFacing();
				// TreeControl.ListOfTotems[TreeControl.LockedTotemIndex].PuzzleNotSolved.Broadcast();
				// TreeControl.ListOfTotems[TreeControl.LockedTotemIndex].BP_OppositeTotemFail();
				// TreeControl.ListOfTotems[TreeControl.LockedTotemIndex].SwapTargetFacing();
			}
			else
			{
				UTundra_River_TotemPuzzle_EffectHandler::Trigger_TriedToGroundSlamWhileAtBottom(this);
			}
		}
		else
		{
			if(!bIsLocked)
			{
				// TotemSlamFail(this, TreeControl.GetOppositeTotem(this));
			}
			else
			{
				BP_SlammedTotemFail();
				PuzzleNotSolved.Broadcast();
			}
		}

		if(TreeControl.LifeComp.IsCurrentlyLifeGiving())
		{
			Game::GetZoe().PlayForceFeedback(ZoeSlamFF, false, false, this);
		}
	}

	UFUNCTION()
	void ToggleEyes(bool bOn)
	{
		if(bOn == bEyesActive)
			return;

		if(bOn)
		{
			if(!bPuzzleSolved)
			{
				LeftEyeActivationComp.Activate(true);
				RightEyeActivationComp.Activate(true);
			}
		}
		else
		{
			LeftEyeActivationComp.Deactivate();
			RightEyeActivationComp.Deactivate();
		}
		bEyesActive = bOn;
	}

	UFUNCTION()
	void SwapTargetFacing()
	{
		if(CurrentFacing == ETundraTotemFacing::Front)
		{
			CurrentFacing = ETundraTotemFacing::Back;
			TargetRotation = 180;
		}
		else
		{
			CurrentFacing = ETundraTotemFacing::Front;
			TargetRotation = 0;
		}
		
		SolutionFacing = CurrentFacing;

		Game::GetZoe().PlayForceFeedback(RotateFF, false, false, this);
		TotemFacingChanged.Broadcast();
	}

	UFUNCTION()
	void SetTargetFacing(ETundraTotemFacing Facing)
	{
		if(Facing == ETundraTotemFacing::Back)
		{
			CurrentFacing = ETundraTotemFacing::Back;
			TargetRotation = 180;
		}
		else
		{
			CurrentFacing = ETundraTotemFacing::Front;
			TargetRotation = 0;
		}
		
		Game::GetZoe().PlayForceFeedback(RotateFF, false, false, this);
		TotemFacingChanged.Broadcast();
	}

	UFUNCTION()
	void TotemSlamFail(ATundra_River_TotemPuzzle SlammedTotem, ATundra_River_TotemPuzzle OppositeTotem)
	{
		// fail movement on slammed totem
		SlammedTotem.BP_SlammedTotemFail();
		// fail movement on opposite totem
		OppositeTotem.BP_OppositeTotemFail();
	}

	UFUNCTION(BlueprintPure)
	int GetSyncedTargetHeight()
	{
		return TargetHeight;
	}

	UFUNCTION(BlueprintPure)
	bool IsAtMaxHeight()
	{
		return TargetHeight == 3;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SlamCooldown > 0)
		{
			SlamCooldown -= DeltaSeconds;
		}

		if(!bSlammable && SlamCooldown <= 0)
		{
			bSlammable = true;
		}
		// bMoveShake = false;

		if(!bPuzzleSolved && !IsAtMaxHeight())
		{
			if(Time::GetGameTimeSince(TimeLastMovedUp) >= MoveUpTime * 0.6 && !bMoveShake && !bPuzzleSolved && !bIsLocked)
			{
				bMoveShake = true;
				Game::GetMio().PlayForceFeedback(ShakeFF, this, Intensity = 0.1);
				
				UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TotemStartShaking(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
			}

			if(Time::GetGameTimeSince(TimeLastMovedUp) >= MoveUpTime && !bIsLocked)
			{
				SetTargetHeight(GetSyncedTargetHeight() + 1, false);
				ResetMoveUpTime();
			}
		}

		// if(!IsAtMaxHeight() && bIsLocked)
		// {
		// 	PrintToScreen("" + Time::GetGameTimeSince(TimeLastLocked));
		// }

		if(bIsLocked && !bPuzzleSolved)
		{
			if(Time::GetGameTimeSince(TimeLastLocked) >= CurrentLockDuration)
			{
				// TimeLastMovedUp = Time::GetGameTimeSeconds() - MoveUpTime * 0.6;
				UnlockTotem();
			}

			if(Time::GetGameTimeSeconds() >= CurrentLockDuration + TimeLastLocked - 1.5 && !bMoveShake && !IsAtMaxHeight())
			{
				bMoveShake = true;
				Game::GetMio().PlayForceFeedback(ShakeFF, this, Intensity = 0.1);
				UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TotemStartShaking(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
			}
		}

		// if(Time::GetGameTimeSince(TimeLastLocked) >= LockDuration && bIsLocked && !bPuzzleSolved)
		// {

		// 	// TimeLastMovedUp = Time::GetGameTimeSeconds() - MoveUpTime * 0.6;
		// 	UnlockTotem();

		// 	// Niagara::SpawnOneShotNiagaraSystemAtLocation(RootsUnlockEfect, ActorLocation + (FVector::RightVector * 100));
		// 	// ResetMoveUpTime();
		// }

		// if(Time::GetGameTimeSince(TimeSolved) >= NextStageDelay && TreeControl.bFirstSolutionSolved && SolutionFacing != ETundraTotemFacing::Back)
		// {
		// 	SwapTargetFacing();
		// 	FirstPuzzleSolved.Broadcast();
		// 	ToggleEyes(false);
		// }
	}

	UFUNCTION()
	void ResetMoveUpTime()
	{
		TimeLastMovedUp = Time::GetGameTimeSeconds();
		bMoveShake = false;
		Game::GetMio().StopForceFeedback(this);
	}

	UFUNCTION()
	void SetTargetStatus(bool bTarget, bool bAnimateRoots = true)
	{
		bIsTargeted = bTarget;
		// bIsLocked = bTarget;

		if(bTarget)
		{
			OnTotemTargeted.Broadcast();
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_TotemTargeted(this);
		}
		else
		{
			OnTotemUntargeted.Broadcast();
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_TotemUntargeted(this);
		}

		if(bAnimateRoots)
			BP_ToggleTargetedMeshes(bTarget);
	}

	UFUNCTION()
	void SetTargetHeight(int Target, bool GroundSlammed, bool Forced = false)
	{
		if(HasControl())
		{
			SlamCooldown = MaxSlamCooldown;
			// bSlammable = false;

			if(Target <= 3 && Target >= 0)
			{	
				CrumbTargetHeightUpdate(Target, GroundSlammed, Forced);
			}

			else
			{
				bool bUp = false;
				if(Target > 0)
					bUp = true;

				CrumbTriedToMoveButIsAtBounds(bUp, GroundSlammed);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriedToMoveButIsAtBounds(bool bUp, bool bGroundSlam)
	{
		if(bGroundSlam)
		{
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_TriedToGroundSlamWhileAtBottom(this);
			UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TriedToGroundSlamWhileTotemAtBottom(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
		}

		else if(bUp)
		{
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_TriedToMoveUpButIsAsHighAsItGoes(this);		
			UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TriedToMoveTotemUpButIsAsHighAsItGoes(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
		}
		else
		{
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_TriedToMoveDownButIsAsLowAsItGoes(this);
			UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TriedToMoveTotemDownButIsAsLowAsItGoes(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
		}
			
	}

	UFUNCTION(CrumbFunction)
	void CrumbTargetHeightUpdate(int Target, bool GroundSlammed, bool Forced = false)
	{
		if(GroundSlammed)
		{
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_GroundSlammed(this);	
			UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TotemGroundSlammed(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
		}
		else if(Target > TargetHeight)
		{
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_MovingUp(this);
			UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TotemMovingUp(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
			MoveCamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		}
		else
		{
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_MovingDown(this);
			UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TotemMovingDown(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
			MoveCamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		}
		
		TargetHeight = Target;
		bLastInputWasAGroundSlam = GroundSlammed;
		TotemHeightChanged.Broadcast();

		bMoveShake = false;
		Game::GetMio().StopForceFeedback(this);
		
		if(TargetHeight == 0)
		{
			UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TotemReachedBottom(TreeControl, FTotemPuzzleEffectParams(TotemIndex));
		}
	}

	UFUNCTION(BlueprintPure)
	float GetSyncedActualHeight()
	{
		return TargetHeight * 240 + 45;
	}

	UFUNCTION(BlueprintPure)
	bool SolutionCheck() const
	{
		if(CurrentFacing == SolutionFacing && TargetHeight == SolutionHeight && bIsLocked)
			return true;
		
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSolvePuzzle()
	{
		if(!TreeControl.bFirstSolutionSolved)
		{
			SolutionHeight = SecondSolutionHeight;
			SetTargetHeight(StartTargetHeight, false, true);
			TimeSolved = Time::GetGameTimeSeconds();
		}
		else
		{
			bPuzzleSolved = true;
			// SetTargetHeight(SolutionHeight, false);
			UnlockTotem();
			PuzzleSolved.Broadcast();
			UTundra_River_TotemPuzzle_EffectHandler::Trigger_PuzzleSolved(this);
			ToggleEyes(false);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbWrongSolution()
	{
		bPuzzleSolved = false;
		PuzzleNotSolved.Broadcast();
		// if(TargetHeight != StartTargetHeight)
		// {
		// 	SetTargetHeight(StartTargetHeight, false);
		// }
		// if(CurrentFacing != StartFacing)
		// {
		// 	SetTargetFacing(StartFacing);
		// }
		UTundra_River_TotemPuzzle_EffectHandler::Trigger_TriedWrongSolution(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ToggleTargetedMeshes(bool bTarget){}

	UFUNCTION(BlueprintEvent)
	void BP_OppositeTotemFail(){}

	UFUNCTION(BlueprintEvent)
	void BP_SlammedTotemFail(){}
	
	UFUNCTION(BlueprintEvent)
	void BP_TotemRaised(){}

	UFUNCTION(BlueprintEvent)
	void BP_LockTotem() {}

	UFUNCTION(BlueprintEvent)
	void BP_UnlockTotem() {}
}