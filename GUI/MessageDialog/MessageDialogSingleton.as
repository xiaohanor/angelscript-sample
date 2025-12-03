struct FActiveMessageDialog
{
	int MessageId = -1;
	FMessageDialog Dialog;
	FInstigator Instigator;
};

class UMessageDialogSingleton : UHazeSingleton
{
	UPROPERTY()
	TSubclassOf<UMessageDialogWidget> DialogWidgetClass;

	UPROPERTY()
	FSoundDefReference SoundDefReference;

	int NextMessageId = 1;
	TArray<FActiveMessageDialog> Messages;
	UMessageDialogWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
	}

	void AddMessage(FMessageDialog Message, FInstigator Instigator)
	{
		FActiveMessageDialog ActiveDialog;
		ActiveDialog.MessageId = NextMessageId;
		++NextMessageId;
		ActiveDialog.Dialog = Message;
		ActiveDialog.Instigator = Instigator;
		
		// If we have no options, add a standard OK option
		if (ActiveDialog.Dialog.Options.Num() == 0)
			ActiveDialog.Dialog.AddOKOption();

		Messages.Add(ActiveDialog);
		Update();
	}

	UFUNCTION()
	void CloseMessage()
	{
		Messages.RemoveAt(0);
		Update();
	}

	void CloseMessageWithInstigator(FInstigator Instigator)
	{
		for (int i = Messages.Num() - 1; i >= 0; --i)
		{
			if (Messages[i].Instigator == Instigator)
				Messages.RemoveAt(i);
		}
		Update();
	}

	private void RemoveMessageWidget()
	{
		if (Widget != nullptr)
		{
			if (Widget.HasFocusedDescendants())
				Widget::ClearAllPlayerUIFocus();
			Widget::RemoveFullscreenWidget(Widget);
			Widget = nullptr;
		}
	}

	void Update()
	{
		if (Messages.Num() == 0)
		{
			// No more messages, remove widget
			RemoveMessageWidget();
			Widget::SetUseMouseCursor(this, false);
		}
		else if (Widget == nullptr || Widget.ActiveMessageId != Messages[0].MessageId)
		{
			if (Widget != nullptr)
				RemoveMessageWidget();

			// Create widget to show messages
			Widget = Widget::AddFullscreenWidget(DialogWidgetClass, EHazeWidgetLayer::Menu);
			Widget.SetWidgetPersistent(true);
			Widget.SetWidgetZOrderInLayer(1000);
			Widget.MessageDialog = Messages[0].Dialog;
			Widget.ActiveMessageId = Messages[0].MessageId;
			Widget.UpdateMessage();
			Widget.Show();

			if (Game::IsNarrationEnabled())
			{
				FString NarrateString = Messages[0].Dialog.Message.ToString();
				if (Messages[0].Dialog.Options.Num() > 0)
				{
					NarrateString += ", ";
					NarrateString += Messages[0].Dialog.Options[0].Label;
					NarrateString += ", ";
					NarrateString += Messages[0].Dialog.Options[0].DescriptionText;
				}
				Game::NarrateString(NarrateString);
			}

			Widget::SetUseMouseCursor(this, true);
			Widget::SetAllPlayerUIFocus(Widget);

			auto AudioActor = Menu::GetAudioActor();
			if (AudioActor != nullptr)
			{
				AddSoundDef(AudioActor);

				UMenuEffectEventHandler::Trigger_OnMessageDialog(
					AudioActor, FMessageDialogData(Widget));
			}
		}
	}

	void AddSoundDef(AHazeActor AudioActor)
	{
		// The sounddef instance might get destroyed.
		if (!SoundDefReference.IsValid())
			return;

		auto SoundDefContext = USoundDefContextComponent::GetOrCreate(AudioActor);
		if (SoundDefContext == nullptr)
			return;

		if (!SoundDefContext.HasSoundDef(SoundDefReference.SoundDef))
		{
			SoundDefReference.SpawnSoundDefAttached(AudioActor);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Poll for errors from the online subsystem
		FText OnlineError;
		if (Online::ConsumeLastError(OnlineError))
		{
			FMessageDialog Message;
			Message.Message = OnlineError;
			AddMessage(Message, this);
		}

		// Poll for questions from the online subsystem
		FHazeOnlineQuestion Question;
		if (Online::ConsumeQuestion(Question))
		{
			FMessageDialog Dialog;
			Dialog.Message = Question.Message;
			Dialog.AddOption(Question.YesText, FOnMessageDialogOptionChosen(this, n"OnOnlineQuestionYes"));
			Dialog.AddOption(Question.NoText, FOnMessageDialogOptionChosen(this, n"OnOnlineQuestionNo"));
			AddMessage(Dialog, this);
		}

		// If a message widget is up it will *always* have focus
		if (Widget != nullptr && Widget.bIsAdded)
			Widget::SetAllPlayerUIFocusBeneathParent(Widget);
	}

	UFUNCTION()
	private void OnOnlineQuestionNo()
	{
		Online::AnswerQuestion(false);
	}

	UFUNCTION()
	private void OnOnlineQuestionYes()
	{
		Online::AnswerQuestion(true);
	}

	void TestMessageDialog()
	{
		FMessageDialog Dialog;
		Dialog.Message = FText::FromString("Test Dialog");
		Dialog.AddOKOption(FOnMessageDialogOptionChosen(this, n"TestDialogConfirmed"));
		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void TestDialogConfirmed()
	{
		Progress::ReturnToMainMenu();
	}
};

const FConsoleCommand Command_TestMessageDialog("Haze.TestMessageDialog", n"ConsoleMessageDialogTest");

local void ConsoleMessageDialogTest(const TArray<FString>& Args)
{
	UMessageDialogSingleton::Get().TestMessageDialog();
}