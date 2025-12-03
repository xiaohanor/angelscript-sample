struct FSummitPipeData
{
	UPROPERTY()
	ASummitMusicSymbol MusicSymbolAcid;

	UPROPERTY()
	ASummitMusicSymbol MusicSymbolTail;
}

class ASummitPipeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditInstanceOnly)
	TArray<FSummitPipeData> Data;

	UPROPERTY(EditInstanceOnly)
	ASummitPipeDoor Door;

	UPROPERTY(EditInstanceOnly)
	TArray<ASummitPipeDoorLockSelector> Selectors;

	TArray<ASummitMusicPipe> Pipes;

	int InternalRow = 0;
	int CorrectTries = 0;

	bool bCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pipes = TListedActors<ASummitMusicPipe>().Array;
		for (ASummitMusicPipe Pipe : Pipes)
		{
			Pipe.OnSummitPipeActivated.AddUFunction(this, n"OnSummitPipeActivated");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			return;

		//Check
		if (!Selectors[0].MovingToTarget() && Selectors[0].GetCurrentIndexHeight() < InternalRow && InternalRow != 0)
		{
			for (int i = InternalRow - 1; i < Data.Num(); i++)
			{
				if (Data[i].MusicSymbolTail != nullptr)
				{
					Data[i].MusicSymbolTail.CrumbSymbolReset();
				}

				if (Data[i].MusicSymbolAcid != nullptr)
				{
					Data[i].MusicSymbolAcid.CrumbSymbolReset();
				}
			}
			
			CorrectTries = 0;
			InternalRow = Selectors[0].GetCurrentIndexHeight();
		}
	}

	UFUNCTION()
	private void OnSummitPipeActivated(ASummitMusicPipe Pipe)
	{
		if (!HasControl())
			return;

		if(bCompleted)
			return;

		//Check if correct
		//start timer
		//fail if either timer runs out, or wrong one is hit
		int RequiredCorrectTries = 0;

		if (Data[InternalRow].MusicSymbolAcid != nullptr)
			RequiredCorrectTries++;

		if (Data[InternalRow].MusicSymbolTail != nullptr)
			RequiredCorrectTries++;

		if (Pipe.PipeType == ESummitMusicPipe::Acid)
		{
			auto Symbol = Data[InternalRow].MusicSymbolAcid;
			if (IsCorrectPipe(Symbol, Pipe))
			{
				if (!Symbol.bSymbolIsComplete)
				{
					CrumbCompleteSymbol(Symbol, false);
					CorrectTries++;
				}
			}
			else
			{
				CrumbResetPipeSequence();
			}
		}
		
		if (Pipe.PipeType == ESummitMusicPipe::Tail)
		{
			auto Symbol = Data[InternalRow].MusicSymbolTail;
			if (IsCorrectPipe(Symbol, Pipe))
			{
				if (!Symbol.bSymbolIsComplete)
				{
					CrumbCompleteSymbol(Symbol, true);
					CorrectTries++;
				}

			}
			else
			{
				CrumbResetPipeSequence();
			}
		}

		if (CorrectTries == RequiredCorrectTries)
		{
			InternalRow++;
			for (ASummitPipeDoorLockSelector Selector : Selectors)
				Selector.CrumbSetTargetIndex(InternalRow);

			CorrectTries = 0;

			USummitPipeManagerEventHandler::Trigger_OnRightAnswer(this);

			if (InternalRow > Data.Num() - 1)
			{
				// WE OPEN THE DOOR
				CrumbCompletePipeSequence();
			}
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbCompleteSymbol(ASummitMusicSymbol Symbol, bool bIsTailDragon)
	{
		Symbol.SetSymbolCorrect(bIsTailDragon);
	}

	bool IsCorrectPipe(ASummitMusicSymbol Symbol, ASummitMusicPipe Pipe) const
	{
		if (Symbol != nullptr)
		{
			if (Symbol.Pipe == Pipe)
				return true;

			return false;
		}

		return false;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbCompletePipeSequence()
	{
		bCompleted = true;
		Door.StartDoorOpeningSequence();
		USummitPipeManagerEventHandler::Trigger_OnPuzzleCompleted(this);
		AddActorDisable(this);
		for(auto Selector : Selectors)
			Selector.CompletePuzzle();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbResetPipeSequence()
	{
		InternalRow = 0;
		CorrectTries = 0;

		for (ASummitPipeDoorLockSelector Selector : Selectors)
			Selector.ResetTargetIndex();

		for (FSummitPipeData CurrentData : Data)
		{
			if (CurrentData.MusicSymbolAcid != nullptr)
			{
				CurrentData.MusicSymbolAcid.SymbolReset();
			}

			if (CurrentData.MusicSymbolTail != nullptr)
			{
				CurrentData.MusicSymbolTail.SymbolReset();
			}
		}

		USummitPipeManagerEventHandler::Trigger_OnWrongAnswer(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for (FSummitPipeData CurrentData : Data)
		{
			if (CurrentData.MusicSymbolAcid != nullptr)
				Debug::DrawDebugLine(ActorLocation, CurrentData.MusicSymbolAcid.ActorLocation, FLinearColor::Green, 10);

			if (CurrentData.MusicSymbolTail != nullptr)
				Debug::DrawDebugLine(ActorLocation, CurrentData.MusicSymbolTail.ActorLocation, FLinearColor::Blue, 10);
		}
	}
#endif
};