event void FPuzzleEvent();
event void FTotemRaised(ATundra_River_TotemPuzzle RaisedTotem);
event void FChangedTargetTotemEvent(ATundra_River_TotemPuzzle TargetTotem);
event void FTotemChangedPosition(ETundraTotemIndex Index, bool bCorrectPosition);

class ATundra_River_TotemPuzzle_TreeControl : AHazeActor
{
	UPROPERTY(BlueprintReadOnly)
	UTundraLifeReceivingComponent LifeComp;

	UPROPERTY(BlueprintReadOnly)
	UTundraTreeGuardianRangedInteractionTargetableComponent LifeTargetComp;

	UPROPERTY(EditInstanceOnly)
	AActor LifeGivingActor;

	UPROPERTY(EditInstanceOnly)
	ATundra_River_TotemPuzzle_MovingRoot MovingRoot;

	UPROPERTY()
	FPuzzleEvent PuzzleIsSolved;

	UPROPERTY()
	FPuzzleEvent PuzzleIsNotSolved;
	
	UPROPERTY()
	FTotemRaised TotemRaised;

	UPROPERTY()
	FChangedTargetTotemEvent ChangedTargetTotem;

	UPROPERTY()
	FTotemChangedPosition TotemChangedPosition;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_River_TotemPuzzle> ListOfTotems;

	UPROPERTY(EditInstanceOnly)
	ATundra_River_TotemPuzzle_Button TotemButton;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect MoveRootFF;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect MoveRootFF1;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect MoveRootFF2;

	UPROPERTY(EditInstanceOnly)
	float ResetCooldown = 1;

	float TimeLastReset;
	int TargetTotemIndex = 1;
	bool bTargetTotemMoveReset = true;
	bool bReset = true;
	bool bPuzzleSolved = false;
	bool bLockHeld = false;
	bool bFirstSolutionSolved = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		#if EDITOR
			devCheck(ListOfTotems.Num() == 3, f"Missing Totems in array of {GetActorLabel()}");
		#endif

		for(auto Totem : ListOfTotems)
		{
			Totem.TreeControl = this;
			Totem.TreeControlSetup();
		}

		if(LifeGivingActor != nullptr)
		{
			LifeComp = UTundraLifeReceivingComponent::Get(LifeGivingActor);
			LifeTargetComp = UTundraTreeGuardianRangedInteractionTargetableComponent::Get(LifeGivingActor);
			LifeComp.OnInteractStart.AddUFunction(this, n"OnLifeGiveStarted");
			LifeComp.OnInteractStop.AddUFunction(this, n"OnLifeGiveStopped");
			LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"OnInteractStarted");
			LifeComp.OnInteractStopDuringLifeGive.AddUFunction(this, n"OnInteractStopped");
		}

		// TotemButton.ButtonSlammedEvent.AddUFunction(this, n"OnButtonSlammed");
	}

	UFUNCTION()
	private void OnInteractStopped()
	{
		// if(bPuzzleSolved || !GetTargetTotem().bIsLocked)
		// 	return;

		// bLockHeld = false;
		// GetTargetTotem().BP_UnlockTotem();
	}

	UFUNCTION()
	private void OnInteractStarted()
	{
		// if(!bReset)
		// 	return;

		if(bPuzzleSolved || GetTargetTotem().bIsLocked)
			return;

		bLockHeld = true;
		// Game::GetZoe().PlayForceFeedback(MoveRootFF, false, false, this);
		// GetTargetTotem().LockTotem();
		MovingRoot.LockTotem(GetTargetTotem());
	}

	UFUNCTION()
	private void OnLifeGiveStarted(bool bForced)
	{
		if(GetTargetTotem() == nullptr)
		{
			SetTotemTargetStatus(ETundraTotemIndex::Middle);
			ChangedTargetTotem.Broadcast(GetTargetTotem());
		}
		BP_LifeGiveStarted();
	}
	
	UFUNCTION()
	private void OnLifeGiveStopped(bool bForced)
	{
		SetTotemTargetStatus(ETundraTotemIndex::NONE);
		BP_LifeGiveStopped();
	}

	// UFUNCTION()
	// private void OnButtonSlammed()
	// {
	// 	SolutionCheck();
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPuzzleSolved || !LifeComp.IsCurrentlyLifeGiving())
			return;

		// TryMoveTargetTotem();
	}

	void SetTotemTargetStatus(ETundraTotemIndex TotemIndex = ETundraTotemIndex::NONE)
	{
		ATundra_River_TotemPuzzle TargetTotem;
		for (auto Totem : ListOfTotems)
		{
			if(TotemIndex != ETundraTotemIndex::NONE)
			{
				if(TotemIndex == Totem.TotemIndex)
				{
					Totem.SetTargetStatus(true, true);
					TargetTotemIndex = int(TotemIndex);
				}
				else
				{
					if(Totem.bIsTargeted)
						Totem.SetTargetStatus(false, true);
				}
			}
			else
			{
				if(Totem.bIsTargeted)
					Totem.SetTargetStatus(false, true);
			}
		}
	}

	// void TryMoveTargetTotem()
	// {
	// 	float Input = MovingRoot.SyncedAlpha.Value;

	// 	// if(Input == 0)
	// 	// 	bTargetTotemMoveReset = true;

	// 	// if(!bTargetTotemMoveReset)
	// 	// 	return;

	// 	if(Input < 0.25)
	// 	{
	// 		SetTargetTotem(ETundraTotemIndex::Left);
	// 		// bTargetTotemMoveReset = false;
	// 	}
	// 	else if(Input > 0.25 && Input < 0.75)
	// 	{
	// 		SetTargetTotem(ETundraTotemIndex::Middle);
	// 		// bTargetTotemMoveReset = false;
	// 	}
	// 	else
	// 	{
	// 		SetTargetTotem(ETundraTotemIndex::Right);
	// 	}
	// }

	UFUNCTION()
	void SolutionCheck()
	{
		if(HasControl() && !bPuzzleSolved)
		{
			bool bPuzzleIsSolved = true;
			for(auto Totem: ListOfTotems)
			{
				bool bSolved = Totem.SolutionCheck();
				CrumbTotemChangedPosition(Totem.TotemIndex, bSolved);
				if(!bSolved)
				{
					bPuzzleIsSolved = false;
				}
			}

			if(bPuzzleIsSolved)
			{
				for(auto Totem: ListOfTotems)
				{
					Totem.CrumbSolvePuzzle();
				}
				OnInteractStopped();
				
				CrumbPuzzleIsSolved();

				if(!bFirstSolutionSolved)
				{
					bFirstSolutionSolved = true;
				}
			}
			else
			{
				for(auto Totem: ListOfTotems)
				{
					Totem.CrumbWrongSolution();
				}
				CrumbPuzzleIsNotSolved();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTotemChangedPosition(ETundraTotemIndex TotemIndex, bool bCorrectPosition)
	{
		TotemChangedPosition.Broadcast(TotemIndex, bCorrectPosition);
	}

	// UFUNCTION()
	// void MoveTargetTotem(int Change)
	// {
	// 	int PreviousTotemIndex = TargetTotemIndex;
	// 	int NewTotemIndex = TargetTotemIndex + Change;

	// 	if(NewTotemIndex <= 2 && NewTotemIndex >= 0)
	// 	{
	// 		TargetTotemIndex += Change;
	// 		ListOfTotems[PreviousTotemIndex].SetTargetStatus(false);
	// 		ListOfTotems[TargetTotemIndex].SetTargetStatus(true);
	// 		Game::GetZoe().PlayForceFeedback(MoveRootFF, false, false, this);
	// 		ChangedTargetTotem.Broadcast(GetTargetTotem());
	// 	}
	// }

	UFUNCTION()
	void SetTargetTotem(ETundraTotemIndex TotemIndex = ETundraTotemIndex::NONE)
	{
		if(GetTargetTotem().TotemIndex == TotemIndex)
			return;

		int PreviousTotemIndex = TargetTotemIndex;
		int NewTotemIndex = int(TotemIndex);

		TargetTotemIndex = NewTotemIndex;
		ListOfTotems[PreviousTotemIndex].SetTargetStatus(false);
		ListOfTotems[TargetTotemIndex].SetTargetStatus(true);
		Game::GetZoe().PlayForceFeedback(MoveRootFF, false, false, this, 1);
		ChangedTargetTotem.Broadcast(GetTargetTotem());
	}

	// UFUNCTION()
	// ATundra_River_TotemPuzzle GetOppositeTotem(ATundra_River_TotemPuzzle SlammedTotem)
	// {
	// 	ATundra_River_TotemPuzzle OppositeTotem;
	// 	for(auto Totem : ListOfTotems)
	// 	{
	// 		if(!Totem.bIsLocked && Totem != SlammedTotem)
	// 		{
	// 			OppositeTotem = Totem;
	// 		}
	// 	}
	// 	return OppositeTotem;
	// }
	
	// UFUNCTION()
	// void OppositeTotemReaction(ATundra_River_TotemPuzzle SlammedTotem)
	// {
	// 	ATundra_River_TotemPuzzle OppositeTotem = GetOppositeTotem(SlammedTotem);
	// 			if(!OppositeTotem.IsAtMaxHeight())
	// 				OppositeTotem.SetTargetHeight(OppositeTotem.TargetHeight + 1, false);
		
	// }

	// UFUNCTION()
	// ATundra_River_TotemPuzzle GetLockedTotem()
	// {
	// 	ATundra_River_TotemPuzzle LockedTotem;
	// 	for(auto Totem : ListOfTotems)
	// 	{
	// 		if(Totem.bIsLocked)
	// 		{
	// 			LockedTotem = Totem;
	// 		}
	// 	}
	// 	return LockedTotem;
	// }

	UFUNCTION()
	ATundra_River_TotemPuzzle GetTargetTotem()
	{
		ATundra_River_TotemPuzzle TargetTotem;
		for(auto Totem : ListOfTotems)
		{
			if(Totem.bIsTargeted)
			{
				TargetTotem = Totem;
				return TargetTotem;
			}
		}

		return nullptr;
	}

	UFUNCTION(CrumbFunction)
	void CrumbPuzzleIsSolved()
	{
		if(!bFirstSolutionSolved)
			return;

		bPuzzleSolved = true;
		PuzzleIsSolved.Broadcast();
		UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_PuzzleSolved(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbPuzzleIsNotSolved()
	{
		// TimeLastReset = Time::GetGameTimeSeconds();
		// bReset = false;
		// if(bLockTotemSetup)
		// 	GetLockedTotem().BP_ToggleLockedMeshes(false);
		PuzzleIsNotSolved.Broadcast();
		UTundra_River_TotemPuzzle_TreeControl_EffectHandler::Trigger_TriedWrongSolution(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_LifeGiveStarted() {}

	UFUNCTION(BlueprintEvent)
	void BP_LifeGiveStopped() {}
}
