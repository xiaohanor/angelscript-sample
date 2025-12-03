
struct FActiveTutorial
{
	int TutorialId = 0;
	FTutorialPrompt Prompt;
	float Timer = 0.0;
	FInstigator Instigator;
	USceneComponent Attach;
	FName AttachSocket = NAME_None;
	FVector Offset;
	UTutorialPromptWidget PromptWidget;
	float ScreenSpaceOffset = 0.0;
	ETutorialPromptState State = ETutorialPromptState::Normal;
};

struct FActiveTutorialChain
{
	int TutorialId = 0;
	FTutorialPromptChain Chain;
	int ChainPosition = 0;
	FInstigator Instigator;
};

struct FCancelPrompt
{
	bool bCustomText = false;
	FText CancelText;
	FInstigator Instigator;
};

UCLASS(HideCategories = "ComponentReplication Activation Cooking Collision")
class UTutorialComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UTutorialContainerWidget> TutorialWidget;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> CancelPromptWidget;

	UPROPERTY()
	TSubclassOf<UTutorialPromptWidget> WorldPromptWidget;

	UPROPERTY()
	TArray<FCancelPrompt> CancelPrompts;

	// Offset in UI pixels to offset all the tutorial prompts up or down
	TInstigated<float> TutorialScreenSpaceOffset;

	bool bHasTutorials = false;
	TArray<FActiveTutorial> ActiveTutorials;
	TArray<FActiveTutorialChain> ActiveChains;
	int NextTutorialId = 0;

	TArray<FActiveTutorial> WorldPrompts;

	AHazePlayerCharacter Player;
	TArray<UTutorialPromptWidget> WorldPromptWidgets;

	UCancelPromptWidget CancelPrompt;
	UCancelPromptWidget PreviousCancelPrompt;
	AHazePlayerCharacter CancelPromptVisibleScreen;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = 0, Count = ActiveTutorials.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = ActiveTutorials[i];
			Tutorial.Timer += DeltaTime;

			// Remove tutorials that have reached their max duration
			if (Tutorial.Prompt.MaximumDuration > 0.0)
			{
				if (Tutorial.Timer > Tutorial.Prompt.MaximumDuration)
				{
					ActiveTutorials.RemoveAt(i);
					--i; --Count;
				}
			}
		}

		for (int i = 0, Count = WorldPrompts.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = WorldPrompts[i];
			Tutorial.Timer += DeltaTime;

			// Remove tutorials that have reached their max duration
			if (Tutorial.Prompt.MaximumDuration > 0.0)
			{
				if (Tutorial.Timer > Tutorial.Prompt.MaximumDuration)
				{
					if (Tutorial.PromptWidget != nullptr)
						Player.RemoveWidget(Tutorial.PromptWidget);
					WorldPrompts.RemoveAt(i);
					--i; --Count;
				}
			}
		}

		if (ActiveTutorials.Num() == 0 && ActiveChains.Num() == 0 && WorldPrompts.Num() == 0 && CancelPrompts.Num() == 0)
		{
			bHasTutorials = false;
			SetComponentTickEnabled(false);
		}

		// Update which screen the cancel prompt should be on
		if (CancelPrompt != nullptr)
		{
			AHazePlayerCharacter ShowOnScreen = Player;
			if (SceneView::IsFullScreen())
				ShowOnScreen = SceneView::FullScreenPlayer;
			if (ShowOnScreen != CancelPromptVisibleScreen)
				UpdateCancelWidget();
		}
	}

	void AddCancelPrompt(bool bCustomText, FText Text, FInstigator Instigator)
	{
		FCancelPrompt Prompt;
		Prompt.bCustomText = bCustomText;
		Prompt.CancelText = Text;
		Prompt.Instigator = Instigator;

		CancelPrompts.Add(Prompt);
		UpdateCancelWidget();
		SetComponentTickEnabled(true);
	}

	void RemoveCancelPrompt(FInstigator Instigator)
	{
		for (int i = CancelPrompts.Num() - 1; i >= 0; --i)
		{
			if (CancelPrompts[i].Instigator == Instigator)
			{
				CancelPrompts.RemoveAt(i);
			}
		}

		UpdateCancelWidget();
	}

	void UpdateCancelWidget()
	{
		AHazePlayerCharacter ShowOnScreen = Player;
		if (SceneView::IsFullScreen())
			ShowOnScreen = SceneView::FullScreenPlayer;

		if (CancelPrompt != nullptr)
		{
			if (CancelPrompts.Num() == 0)
			{
				Player.RemoveWidgetFromHUD(CancelPrompt);
				PreviousCancelPrompt = CancelPrompt;
				CancelPrompt = nullptr;
			}

			if (ShowOnScreen != CancelPromptVisibleScreen)
			{
				if (PreviousCancelPrompt != nullptr && PreviousCancelPrompt.bIsInDelayedRemove)
				{
					PreviousCancelPrompt.FinishRemovingWidget();
					PreviousCancelPrompt = nullptr;
				}

				Player.RemoveWidgetFromHUD(CancelPrompt);
				CancelPrompt.FinishRemovingWidget();

				CancelPrompt = Cast<UCancelPromptWidget>(ShowOnScreen.AddWidgetToHUDSlot(n"CancelPrompt", CancelPromptWidget));
				CancelPrompt.OverrideWidgetPlayer(Player);
				CancelPromptVisibleScreen = ShowOnScreen;
			}
		}
		else
		{
			if (CancelPrompts.Num() != 0)
			{
				if (PreviousCancelPrompt != nullptr && PreviousCancelPrompt.bIsInDelayedRemove)
				{
					PreviousCancelPrompt.FinishRemovingWidget();
					PreviousCancelPrompt = nullptr;
				}
				
				CancelPrompt = Cast<UCancelPromptWidget>(ShowOnScreen.AddWidgetToHUDSlot(n"CancelPrompt", CancelPromptWidget));
				CancelPrompt.OverrideWidgetPlayer(Player);
				CancelPromptVisibleScreen = ShowOnScreen;
			}
		}

		if (CancelPrompts.Num() != 0 && CancelPrompt != nullptr)
		{
			if (CancelPrompts.Last().bCustomText)
				CancelPrompt.CancelText = CancelPrompts.Last().CancelText;
			else
				CancelPrompt.CancelText = CancelPrompt.DefaultCancelText;
			CancelPrompt.Update();
		}
	}

	void AddTutorial(FTutorialPrompt Prompt, FInstigator Instigator)
	{
		// We don't accept tutorials that go away on their own
		// on the remote side, since we can't properly remove them
		if (!HasControl() && Prompt.Mode != ETutorialPromptMode::Default)
			return;

		FActiveTutorial Tutorial;
		Tutorial.Prompt = Prompt;
		Tutorial.Instigator = Instigator;
		Tutorial.TutorialId = NextTutorialId;
		++NextTutorialId;

		ActiveTutorials.Add(Tutorial);

		bHasTutorials = true;
		SetComponentTickEnabled(true);
	}

	void AddTutorialChain(FTutorialPromptChain PromptChain, FInstigator Instigator, int InitialPosition)
	{
		FActiveTutorialChain Chain;
		Chain.Chain = PromptChain;
		Chain.Instigator = Instigator;
		Chain.TutorialId = NextTutorialId;
		++NextTutorialId;
		Chain.ChainPosition = InitialPosition;

		ActiveChains.Add(Chain);

		bHasTutorials = true;
		SetComponentTickEnabled(true);
	}

	void SetPromptState(FInstigator Instigator, ETutorialPromptState State)
	{
		for (int i = 0, Count = ActiveTutorials.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = ActiveTutorials[i];
			if (Tutorial.Instigator == Instigator)
				Tutorial.State = State;
		}

		for (int i = 0, Count = WorldPrompts.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = WorldPrompts[i];
			if (Tutorial.Instigator == Instigator)
				Tutorial.State = State;
		}
	}

	void SetChainPosition(FInstigator Instigator, int ChainPosition)
	{
		for (int i = 0, Count = ActiveChains.Num(); i < Count; ++i)
		{
			FActiveTutorialChain& Tutorial = ActiveChains[i];
			if (Tutorial.Instigator == Instigator)
				Tutorial.ChainPosition = ChainPosition;
		}
	}

	void RemoveTutorialsByInstigator(FInstigator Instigator)
	{
		for (int i = 0, Count = ActiveTutorials.Num(); i < Count; ++i)
		{
			FActiveTutorial& Tutorial = ActiveTutorials[i];
			if (Tutorial.Instigator == Instigator)
			{
				ActiveTutorials.RemoveAt(i);
				--i; --Count;
			}
		}

		for (int i = 0, Count = ActiveChains.Num(); i < Count; ++i)
		{
			FActiveTutorialChain& Tutorial = ActiveChains[i];
			if (Tutorial.Instigator == Instigator)
			{
				ActiveChains.RemoveAt(i);
				--i; --Count;
			}
		}

		bool bWorldPromptsChanged = false;
		for (int i = WorldPrompts.Num() - 1; i >= 0; --i)
		{
			if (WorldPrompts[i].Instigator == Instigator)
			{
				if (WorldPrompts[i].PromptWidget != nullptr)
					Player.RemoveWidget(WorldPrompts[i].PromptWidget);
				WorldPrompts.RemoveAt(i);
				bWorldPromptsChanged = true;
			}
		}

		if (bWorldPromptsChanged)
			UpdateWorldPromptWidgets();
	}

	void AddWorldPrompt(FTutorialPrompt Prompt, FInstigator Instigator, USceneComponent Attach, FVector Offset, float ScreenSpaceOffset, FName AttachSocket = NAME_None)
	{
		FActiveTutorial Tutorial;
		Tutorial.Prompt = Prompt;
		Tutorial.Instigator = Instigator;
		Tutorial.TutorialId = NextTutorialId;
		++NextTutorialId;
		Tutorial.Offset = Offset;
		Tutorial.ScreenSpaceOffset = ScreenSpaceOffset;

		if (Attach != nullptr)
			Tutorial.Attach = Attach;
		else
			Tutorial.Attach = Player.Mesh;
		Tutorial.AttachSocket = AttachSocket;

		WorldPrompts.Add(Tutorial);
		UpdateWorldPromptWidgets();
		SetComponentTickEnabled(true);
	}

	void UpdateWorldPromptWidgets()
	{
		// Add new widgets
		for (int i = 0, Count = WorldPrompts.Num(); i < Count; ++i)
		{
			FActiveTutorial& ActivePrompt = WorldPrompts[i];

			// Don't create a widget if we already have one
			if (ActivePrompt.PromptWidget != nullptr)
				continue;

			// Don't create a widget if we have a previous prompt with the same attach point
			bool bAllowed = true;
			for (int j = 0; j < i; ++j)
			{
				const FActiveTutorial& OtherPrompt = WorldPrompts[j];
				if (OtherPrompt.Attach == ActivePrompt.Attach)
				{
					bAllowed = false;
					break;
				}
			}

			if (!bAllowed)
				continue;

			auto WorldPrompt = Player.AddWidget(WorldPromptWidget);
			WorldPrompt.Prompt = ActivePrompt.Prompt;
			WorldPrompt.AttachWidgetToComponent(ActivePrompt.Attach, ActivePrompt.AttachSocket);
			WorldPrompt.SetWidgetRelativeAttachOffset(ActivePrompt.Offset);
			WorldPrompt.SetWidgetShowInFullscreen(true);
			WorldPrompt.bIsWorldSpace = true;
			WorldPrompt.SetRenderTranslation(FVector2D(0.0, -ActivePrompt.ScreenSpaceOffset));

			if (ActivePrompt.Prompt.OverrideControlsPlayer == EHazeSelectPlayer::Mio)
				WorldPrompt.OverrideWidgetPlayer(Game::Mio);
			else if (ActivePrompt.Prompt.OverrideControlsPlayer == EHazeSelectPlayer::Zoe)
				WorldPrompt.OverrideWidgetPlayer(Game::Zoe);

			WorldPrompt.Show();
			WorldPrompt.AnimateShow();

			ActivePrompt.PromptWidget = WorldPrompt;
		}
	}
};