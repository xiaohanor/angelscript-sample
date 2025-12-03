
class UTutorialPromptWidget : UHazeUserWidget
{
	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation ShowAnim;
	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation HideAnim;

	UPROPERTY(BindWidget)
	UInputButtonWidget Button;

	int TutorialId = 0;
	bool bHiding = false;
	bool bFinishedHiding = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	FTutorialPrompt Prompt;

	UPROPERTY(BlueprintReadOnly)
	bool bIsWorldSpace = false;

	UPROPERTY(BlueprintReadOnly)
	ETutorialPromptState State = ETutorialPromptState::Normal;

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void Show() {}

	UFUNCTION(BlueprintEvent)
	void Hide() {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void UpdateIcon() {}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Button.OnDisplayedKeyChanged.AddUFunction(this, n"OnKeyChanged");
	}

	UFUNCTION()
	private void OnKeyChanged()
	{
		UpdateIcon();
	}

	void AnimateShow()
	{
		StopAllAnimations();
		PlayAnimation(ShowAnim);
	}

	void AnimateHide()
	{
		bHiding = true;

		if (IsAnimationPlaying(ShowAnim))
		{
			StopAllAnimations();
			OnHideFinished();
		}
		else
		{
			PlayAnimation(HideAnim);
			BindToAnimationFinished(HideAnim, FWidgetAnimationDynamicEvent(this, n"OnHideFinished"));
		}
	}

	UFUNCTION()
	private void OnHideFinished()
	{
		bFinishedHiding = true;
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetPromptColor() const
	{
		return Player.GetPlayerUIColor();
	}

	UFUNCTION(BlueprintPure)
	bool ShowAsStickIcon()
	{
		if (Prompt.DisplayType == ETutorialPromptDisplay::Action)
		{
			if (Button.DisplayedKey == EKeys::Gamepad_LeftThumbstick || Button.DisplayedKey == EKeys::Gamepad_RightThumbstick)
				return true;
			return false;
		}

		if (Prompt.DisplayType == ETutorialPromptDisplay::ActionHold)
			return false;
		if (Prompt.DisplayType == ETutorialPromptDisplay::ActionRelease)
			return false;

		if (Prompt.DisplayType == ETutorialPromptDisplay::LeftStick_Press
			|| Prompt.DisplayType == ETutorialPromptDisplay::RightStick_Press)
		{
			// Stick press degrades to 'Action' display on Keyboard
			auto InputComp = UHazeInputComponent::Get(Player);
			auto ControllerType = InputComp.GetControllerType();
			if (ControllerType == EHazePlayerControllerType::Keyboard)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintPure)
	ETutorialPromptDisplay GetPromptDisplay()
	{
		if (Prompt.DisplayType == ETutorialPromptDisplay::Action)
		{
			if (Button.DisplayedKey == EKeys::Gamepad_LeftThumbstick)
				return ETutorialPromptDisplay::LeftStick_Press;
			if (Button.DisplayedKey == EKeys::Gamepad_RightThumbstick)
				return ETutorialPromptDisplay::RightStick_Press;
		}
		return Prompt.DisplayType;
	}

	UFUNCTION(BlueprintEvent)
	void OnStateChanged(ETutorialPromptState PreviousState, ETutorialPromptState NewState) {}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
		bHiding = true;

		if (IsAnimationPlaying(ShowAnim))
		{
			StopAllAnimations();
			OnRemoveFinished();
		}
		else
		{
			PlayAnimation(HideAnim);
			BindToAnimationFinished(HideAnim, FWidgetAnimationDynamicEvent(this, n"OnRemoveFinished"));
		}
	}

	UFUNCTION()
	private void OnRemoveFinished()
	{
		bFinishedHiding = true;
		FinishRemovingWidget();
	}
};

class UTutorialPromptChainWidget : UHazeUserWidget
{
	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation ShowAnim;
	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation HideAnim;

	int TutorialId = 0;
	bool bHiding = false;
	bool bFinishedHiding = false;

	UPROPERTY(BlueprintReadOnly)
	FTutorialPromptChain PromptChain;

	UPROPERTY(BlueprintReadOnly)
	int ChainPosition = 0;

	UFUNCTION(BlueprintEvent)
	UTutorialPromptWidget GetTutorialForPosition(int Position)
	{
		return nullptr;
	}

	void ShowInnerTutorials()
	{
		for (int i = 0, Count = PromptChain.Prompts.Num(); i < Count; ++i)
		{
			auto Widget = GetTutorialForPosition(i);
			if (Widget != nullptr)
			{
				Widget.Prompt = PromptChain.Prompts[i];
				if (Widget.Prompt.OverrideControlsPlayer == EHazeSelectPlayer::Mio)
					Widget.OverrideWidgetPlayer(Game::Mio);
				else if (Widget.Prompt.OverrideControlsPlayer == EHazeSelectPlayer::Zoe)
					Widget.OverrideWidgetPlayer(Game::Zoe);
				Widget.Show();
			}
		}
	}

	void AnimateShow()
	{
		StopAllAnimations();
		PlayAnimation(ShowAnim);
	}

	void AnimateHide()
	{
		bHiding = true;
		PlayAnimation(HideAnim);
		BindToAnimationFinished(HideAnim, FWidgetAnimationDynamicEvent(this, n"OnHideFinished"));
	}

	UFUNCTION()
	private void OnHideFinished()
	{
		bFinishedHiding = true;
	}

	UFUNCTION(BlueprintEvent)
	void Show() {}

	UFUNCTION(BlueprintEvent)
	void Hide() {}
};

class UTutorialContainerWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UBorder OuterBorder;
	UPROPERTY(BindWidget)
	UHorizontalBox Container;

	UPROPERTY()
	TSubclassOf<UTutorialPromptWidget> PromptWidgetClass;

	UPROPERTY()
	TSubclassOf<UTutorialPromptChainWidget> ChainWidgetClass;

	float ScreenSpaceOffset = 0;

	private TArray<UTutorialPromptWidget> PromptWidgets;
	private TArray<UTutorialPromptChainWidget> ChainWidgets;
	private bool bHiding;

	void AddPrompt(int TutorialId, FTutorialPrompt Prompt)
	{
		check(!bHiding);

		for (auto Existing : PromptWidgets)
		{
			if (Existing.TutorialId == TutorialId)
			{
				Existing.Prompt = Prompt;
				return;
			}
		}

		UTutorialPromptWidget Widget = Cast<UTutorialPromptWidget>(Widget::CreateWidget(this, PromptWidgetClass));
		
		Widget.TutorialId = TutorialId;
		Widget.Prompt = Prompt;

		PromptWidgets.Add(Widget);

		if (Prompt.OverrideControlsPlayer == EHazeSelectPlayer::Mio)
			Widget.OverrideWidgetPlayer(Game::Mio);
		else if (Prompt.OverrideControlsPlayer == EHazeSelectPlayer::Zoe)
			Widget.OverrideWidgetPlayer(Game::Zoe);
		else if (Widget.Player != Player)
			Widget.OverrideWidgetPlayer(Player);
		
		SnapAllHideAnimations();
		Container.AddChild(Widget);

		Widget.Show();
		Widget.AnimateShow();
	}

	void SetPromptState(int TutorialId, ETutorialPromptState State)
	{
		for (int i = 0, Count = PromptWidgets.Num(); i < Count; ++i)
		{
			if (PromptWidgets[i].TutorialId == TutorialId)
			{
				if (PromptWidgets[i].State != State)
				{
					auto PreviousState = PromptWidgets[i].State;
					PromptWidgets[i].State = State;

					PromptWidgets[i].OnStateChanged(PreviousState, State);
				}
			}
		}
	}

	void AddChain(int TutorialId, FTutorialPromptChain PromptChain, int ChainPosition)
	{
		check(!bHiding);

		for (auto Existing : ChainWidgets)
		{
			if (Existing.TutorialId == TutorialId)
			{
				Existing.PromptChain = PromptChain;
				Existing.ChainPosition = ChainPosition;
				return;
			}
		}

		UTutorialPromptChainWidget Widget = Cast<UTutorialPromptChainWidget>(Widget::CreateWidget(this, ChainWidgetClass));
		Widget.TutorialId = TutorialId;
		Widget.PromptChain = PromptChain;
		Widget.ChainPosition = ChainPosition;

		ChainWidgets.Add(Widget);

		Widget.ShowInnerTutorials();
		Widget.Show();

		SnapAllHideAnimations();
		Container.AddChild(Widget);
	}

	void SetChainPosition(int TutorialId, int ChainPosition)
	{
		for (int i = 0, Count = ChainWidgets.Num(); i < Count; ++i)
		{
			if (ChainWidgets[i].TutorialId == TutorialId)
				ChainWidgets[i].ChainPosition = ChainPosition;
		}
	}

	void RemovePrompt(int TutorialId)
	{
		for (int i = 0, Count = PromptWidgets.Num(); i < Count; ++i)
		{
			if (PromptWidgets[i].TutorialId == TutorialId)
			{
				if (!PromptWidgets[i].bHiding)
					PromptWidgets[i].AnimateHide();
			}
		}

		for (int i = 0, Count = ChainWidgets.Num(); i < Count; ++i)
		{
			if (ChainWidgets[i].TutorialId == TutorialId)
			{
				if (!ChainWidgets[i].bHiding)
					ChainWidgets[i].AnimateHide();
			}
		}
	}

	void Hide()
	{
		for (int i = PromptWidgets.Num() - 1; i >= 0; --i)
		{
			if (!PromptWidgets[i].bHiding)
				PromptWidgets[i].AnimateHide();
		}

		for (int i = ChainWidgets.Num() - 1; i >= 0; --i)
		{
			if (!ChainWidgets[i].bHiding)
				ChainWidgets[i].AnimateHide();
		}

		bHiding = true;
	}

	void UpdatePrompts()
	{
		for (int i = PromptWidgets.Num() - 1; i >= 0; --i)
		{
			if (PromptWidgets[i].bFinishedHiding)
			{
				Container.RemoveChild(PromptWidgets[i]);
				PromptWidgets.RemoveAt(i);
			}
		}

		for (int i = ChainWidgets.Num() - 1; i >= 0; --i)
		{
			if (ChainWidgets[i].bFinishedHiding)
			{
				Container.RemoveChild(ChainWidgets[i]);
				ChainWidgets.RemoveAt(i);
			}
		}
	}

	void SnapAllHideAnimations()
	{
		for (int i = PromptWidgets.Num() - 1; i >= 0; --i)
		{
			if (PromptWidgets[i].bHiding)
			{
				Container.RemoveChild(PromptWidgets[i]);
				PromptWidgets.RemoveAt(i);
			}
		}

		for (int i = ChainWidgets.Num() - 1; i >= 0; --i)
		{
			if (ChainWidgets[i].bHiding)
			{
				Container.RemoveChild(ChainWidgets[i]);
				ChainWidgets.RemoveAt(i);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bHiding)
		{
			UpdatePrompts();
			if (PromptWidgets.Num() == 0 && ChainWidgets.Num() == 0)
				Player.RemoveWidgetFromHUD(this);
		}

		OuterBorder.SetPadding(
			FMargin(
				0,
				ScreenSpaceOffset,
				0,
				-ScreenSpaceOffset,
			)
		);
	}
};