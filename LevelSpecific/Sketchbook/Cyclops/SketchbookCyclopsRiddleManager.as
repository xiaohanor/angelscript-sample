struct FSketchbookCyclopsRiddle
{
	UPROPERTY(EditInstanceOnly)
	TArray<ASketchbookSentence> RiddleSentences;

	UPROPERTY(EditInstanceOnly)
	TArray<ASketchbookSelectable> Selectables;

	UPROPERTY(EditInstanceOnly)
	TArray<ASketchbookSentence> RiddleWrong;

	UPROPERTY(EditInstanceOnly)
	TArray<ASketchbookSentence> RiddlePassed;

	TArray<USketchbookCyclopsRiddleSelectableComponent> Answers;
}

struct FSketchbookCyclopsColorAnswer
{
	UPROPERTY()
	FText SuccessText;
	
	UPROPERTY()
	FText FailText;

	UPROPERTY()
	UHazeVoxAsset SuccessVoxAsset;

	UPROPERTY()
	UHazeVoxAsset FailVoxAsset;
}

event void FSketchbookQuizOnIntroFinished();

event void FSketchbookQuizCyclopsKilled();

event void FSketchbookQuizCompleted();


class ASketchbookCyclopsRiddleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	TArray<ASketchbookSentence> Introduction;

	UPROPERTY(EditInstanceOnly)
	TArray<FSketchbookCyclopsRiddle> Riddles;

	UPROPERTY(EditInstanceOnly)
	TArray<FSketchbookCyclopsColorAnswer> SelectedColorOptionText;

	UPROPERTY(EditInstanceOnly)
	ASketchbookSentence Blarg;

	ASketchbookCyclops Cyclops;

	bool bCyclopsShot = false;


	TArray<ASketchbookSentence> CurrentSentences;
	TArray<USketchbookCyclopsRiddleSelectableComponent> CurrentAnswers;

	FSketchbookQuizOnIntroFinished OnIntroFinished;
	
	UPROPERTY()
	FSketchbookQuizCyclopsKilled OnCyclopsKilled;

	UPROPERTY()
	FSketchbookQuizCompleted OnQuizCompleted;

	int RiddleStage = 0;

	TArray<int> JumpCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto& Riddle : Riddles)
		{
			Riddle.Answers.Empty();
			
			for(auto Selectable : Riddle.Selectables)
			{
				auto Comp = USketchbookCyclopsRiddleSelectableComponent::Get(Selectable);
				Riddle.Answers.Add(Comp);
			}
		}

		OnCyclopsKilled.AddUFunction(this, n"CyclopsKilled");

	}

	UFUNCTION()
	private void CyclopsKilled()
	{
	}

	void SetCyclops(ASketchbookCyclops InCyclops)
	{
		Cyclops = InCyclops;
	}

	void StartIntro()
	{
		DrawSentences(Introduction);
		Introduction.Last().OnFinishedBeingDrawn.AddUFunction(this, n"IntroDone");
	}

	UFUNCTION()
	private void IntroDone()
	{
		OnIntroFinished.Broadcast();
	}

	void StartRiddles()
	{
		if(bCyclopsShot)
			return;

		EraseAllSentences();
		DrawSentences(Riddles[RiddleStage].RiddleSentences);
		DrawAnswers();
	}

	void DrawAnswers()
	{
		if(bCyclopsShot)
			return;

		for(int i = 0; i < Riddles[RiddleStage].Answers.Num(); i++)
		{
			Riddles[RiddleStage].Answers[i].OnAnswerSelected.AddUFunction(this, n"OnAnswerSelected");
			Sketchbook::SketchbookRequestDrawActor(Riddles[RiddleStage].Answers[i].Text);
			CurrentAnswers.Add(Riddles[RiddleStage].Answers[i]);

			if(i == Riddles[RiddleStage].Answers.Num() - 1)
				Riddles[RiddleStage].Answers[i].Text.OnFinishedBeingDrawn.AddUFunction(this, n"OnLastAnswerDrawn");
		}

		if(HasControl())
		{
			if(RiddleStage == 1)
			{
				RandomizeJumpRiddle();
			}
			else if(RiddleStage == 2)
			{
				int CorrectAnswerIndex = Math::RandRange(0, 2);
				CrumbSetCorrectColorAnswerIndex(CorrectAnswerIndex);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetCorrectColorAnswerIndex(int CorrectAnswerIndex)
	{
		Riddles[RiddleStage].Answers[CorrectAnswerIndex].bIsCorrectAnswer = true;
	}

	void RandomizeJumpRiddle()
	{
		int Jumps = Game::GetSingleton(UPlayerJumpCounter).TotalJumps;
		Jumps = Math::Clamp(Jumps, 0, Jumps);

		int CorrectAnswerIndex = Math::RandRange(0, 2);
		int FirstWrongAnswer = -1;


		for(int i = 0; i < Riddles[RiddleStage].Answers.Num(); i++)
		{
			auto& Answer = Riddles[RiddleStage].Answers[i];

			if(i == CorrectAnswerIndex)
			{
				Answer.Text.DrawableSentenceComp.GetTextRenderComponent().SetText(FText::FromString(""+Jumps));
				Answer.bIsCorrectAnswer = true;
				JumpCount.Add(Jumps);
				continue;
			}

			Answer.bIsCorrectAnswer = false;

			int RandomValue;

			if(FirstWrongAnswer == -1)
			{
				RandomValue = Math::RoundToInt(Jumps * Math::RandRange(0.1, 0.15));
				FirstWrongAnswer = RandomValue;
			}
			else
			{
				if(Math::RandRange(0, 1) == 0)
				{
					RandomValue = Math::RoundToInt(Jumps * Math::RandRange(1.5, 2));
				}
				else
				{
					RandomValue = Math::RoundToInt(Jumps * Math::RandRange(0.5, 0.75));
				}
			}

			JumpCount.Add(RandomValue);
		}

		CrumbSetJumpRiddle(JumpCount, CorrectAnswerIndex);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetJumpRiddle(TArray<int> Answers, int CorrectAnswerIndex)
	{
		JumpCount = Answers;

		for(int i = 0; i < Riddles[RiddleStage].Answers.Num(); i++)
		{
			auto& Answer = Riddles[RiddleStage].Answers[i];

			Answer.bIsCorrectAnswer = false;
			if(i == CorrectAnswerIndex)
			{
				Answer.bIsCorrectAnswer = true;
			}

			Answer.Text.DrawableSentenceComp.GetTextRenderComponent().SetText(FText::FromString(""+ Answers[i]));
		}

		for(auto Player : Game::GetPlayers())
		{
			UPlayerJumpComponent::Get(Player).OnJump.AddUFunction(this, n"IncrementJumpCount");
		}
	}

	UFUNCTION()
	private void IncrementJumpCount(AHazePlayerCharacter Player)
	{
		if(RiddleStage != 1)
		{
			UPlayerJumpComponent::Get(Player).OnJump.Unbind(this, n"IncrementJumpCount");
			return;
		}

		for(int i = 0; i < Riddles[RiddleStage].Answers.Num(); i++)
		{
			JumpCount[i]++;
			auto& Answer = Riddles[RiddleStage].Answers[i];
			Answer.Text.DrawableSentenceComp.GetTextRenderComponent().SetText(FText::FromString(""+ JumpCount[i]));
		}
	}

	void EndRiddle()
	{
		EraseAnswers();
		EraseAllSentences();
	}

	UFUNCTION()
	void OnLastAnswerDrawn()
	{
		for(int i = 0; i < Riddles[RiddleStage].Answers.Num(); i++)
		{
			Riddles[RiddleStage].Answers[i].Selectable.EnableChoice();
		}
	}

	void EraseAnswers()
	{
		for(int i = CurrentAnswers.Num() - 1; i >= 0; i--)
		{
			Sketchbook::SketchbookRequestEraseActor(CurrentAnswers[i].Text);
			CurrentAnswers[i].Selectable.DisableChoice();
		}
	}

	UFUNCTION(DevFunction)
	void DevCorrectAnswer()
	{
		for(auto Answer : Riddles[RiddleStage].Selectables)
		{
			auto SelectableComp = USketchbookCyclopsRiddleSelectableComponent::Get(Answer);
			if(SelectableComp.bIsCorrectAnswer)
			{
				OnAnswerSelected(SelectableComp);
				break;
			}
		}
	}

	UFUNCTION()
	void OnAnswerSelected(USketchbookCyclopsRiddleSelectableComponent Answer)
	{
		EraseAnswers();
		EraseAllSentences();

		if(RiddleStage == 2)
		{
			int CorrectAnswerIndex = -1;

			for(int i = 0; i < Riddles[RiddleStage].Answers.Num(); i++)
			{
				if(Riddles[RiddleStage].Answers[i].bIsCorrectAnswer)
				{
					CorrectAnswerIndex = i;
					break;
				}
			}


			if(Answer.bIsCorrectAnswer)
			{
				Riddles[RiddleStage].RiddlePassed[1].DrawableSentenceComp.GetTextRenderComponent().SetText(SelectedColorOptionText[CorrectAnswerIndex].SuccessText);
				Riddles[RiddleStage].RiddlePassed[1].VoxAsset = SelectedColorOptionText[CorrectAnswerIndex].SuccessVoxAsset;
				Riddles[RiddleStage].RiddlePassed[1].CalculateVoxDuration();
				Riddles[RiddleStage].RiddlePassed.Last().OnFinishedBeingDrawn.AddUFunction(this, n"QuizCompleted");
				DrawSentences(Riddles[RiddleStage].RiddlePassed);
			}
			else
			{				
				Riddles[RiddleStage].RiddleWrong[1].DrawableSentenceComp.GetTextRenderComponent().SetText(SelectedColorOptionText[CorrectAnswerIndex].FailText);
				Riddles[RiddleStage].RiddleWrong[1].VoxAsset = SelectedColorOptionText[CorrectAnswerIndex].FailVoxAsset;
				Riddles[RiddleStage].RiddleWrong[1].CalculateVoxDuration();
				DrawSentences(Riddles[RiddleStage].RiddleWrong);
			}

			return;
		}

		if(Answer.bIsCorrectAnswer)
		{
			DrawSentences(Riddles[RiddleStage].RiddlePassed);

			RiddleStage++;

			DrawSentences(Riddles[RiddleStage].RiddleSentences);
			DrawAnswers();
		}
		else
		{
			DrawSentences(Riddles[RiddleStage].RiddleWrong);
		}
	}

	UFUNCTION()
	private void QuizCompleted()
	{
		OnQuizCompleted.Broadcast();
	}

	void EraseAllSentences()
	{
		//Temporarily all sentences will be destroyed until Filip adds support for erasing multiple actors at once
		for(auto Sentence : CurrentSentences)
		{
			Sentence.DestroyActor();
		}
		
		//Sketchbook::SketchbookRequestEraseActors(CurrentSentences);
		CurrentSentences.Empty();
	}

	void EraseEverythingInstant()
	{
		for(auto Answer : CurrentAnswers)
		{
			Answer.Text.AddActorVisualsBlock(this);
			Answer.Selectable.DisableChoice();
		}

		for(auto Sentence : CurrentSentences)
		{
			Sentence.AddActorVisualsBlock(this);
		}
	}

	void DrawSentence(ASketchbookSentence Sentence)
	{
		CurrentSentences.Add(Sentence);
		Sketchbook::SketchbookRequestDrawActor(Sentence);
	}

	void DrawSentences(TArray<ASketchbookSentence> Sentences)
	{
		CurrentSentences.Append(Sentences);
		Sketchbook::SketchbookRequestDrawActors(Sentences);

	}

	void OnCyclopsShot()
	{
		if(bCyclopsShot)
			return;
		
		bCyclopsShot = true;
		Sketchbook::GetNarrator().CancelNarratorVox();
		Sketchbook::SketchbookCancelAllRequests(false, true);
		Sketchbook::SketchbookRequestDrawActor(Blarg);
		EraseEverythingInstant();
		Cyclops.Fall();
		OnCyclopsKilled.Broadcast();
	}
};

namespace Sketchbook
{
	UFUNCTION(BlueprintPure)
	ASketchbookCyclopsRiddleManager GetRiddleManager()
	{
		return TListedActors<ASketchbookCyclopsRiddleManager>().Single;
	}

	UFUNCTION(BlueprintCallable)
	void StartCyclopsRiddleIntro()
	{
		GetRiddleManager().StartIntro();
	}

	UFUNCTION(BlueprintCallable)
	void StartCyclopsRiddle()
	{
		GetRiddleManager().StartRiddles();
	}
}