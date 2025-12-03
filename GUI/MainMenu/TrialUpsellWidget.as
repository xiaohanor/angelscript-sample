const FConsoleCommand Command_TrialUpsell("Haze.TrialUpsell", n"ConsoleTrialUpsell");

class UTrialUpsellWidget : UHazeUserWidget
{
	default bIsFocusable = true;

	UPROPERTY(BindWidget)
	UPauseMenuButton PurchaseButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton ReturnButton;
	UPROPERTY(BindWidget)
	UWidget Spinner;

	UPROPERTY(Category="Sounds")
	FSoundDefReference SoundDefReference;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		Game::HazeGameInstance.bTrialUpsellActive = true;
		Game::SetGamePaused(this, true);

		Widget::SetAllPlayerUIFocus(PurchaseButton);
		Widget::SetUseMouseCursor(this, true);
		SetWidgetZOrderInLayer(150);
		SetWidgetPersistent(true);

		PurchaseButton.OnClicked.AddUFunction(this, n"OnPurchaseClicked");
		ReturnButton.OnClicked.AddUFunction(this, n"OnReturnClicked");

		Telemetry::TriggerImmediateSpecialEvent("demo_upsell_shown");

		Menu::AttachSoundDef(SoundDefReference, this);
		UMenuEffectEventHandler::Trigger_OnTrailUpsell(Menu::GetAudioActor(), FTrialUpsellData(this, true));
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		// Make sure we kill any potential loop, since the sounddef might still stick around.
		UMenuEffectEventHandler::Trigger_OnTrailUpsell(Menu::GetAudioActor(), FTrialUpsellData(this, false));
		Menu::RemoveSoundDef(SoundDefReference, this);
	}

	UFUNCTION()
	private void OnReturnClicked(UMenuButtonWidget Button)
	{
		if (!IsBusy())
			ReturnToMain();
	}

	UFUNCTION()
	private void OnPurchaseClicked(UMenuButtonWidget Button)
	{
		if (!IsBusy())
		{
			Telemetry::TriggerImmediateSpecialEvent("demo_upsell_clicked");
			Online::ShowStorePage();
		}
	}

	void CloseWidget()
	{
		Game::SetGamePaused(this, false);
		Widget::SetUseMouseCursor(this, false);
		Widget::ClearAllPlayerUIFocus();
		Widget::RemoveFullscreenWidget(this);
		Game::HazeGameInstance.bTrialUpsellActive = false;
	}

	UFUNCTION()
	void ReturnToMain()
	{
		Progress::ReturnToMainMenu();
	}

	UFUNCTION(BlueprintPure)
	bool IsBusy()
	{
		FText DummyText;
		return Online::HasBusyTask(DummyText);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// If the user buys the game, close this dialog!
		if (!DemoUpsell::NeedsUpsell() || Lobby::GetLobby() == nullptr)
		{
			CloseWidget();
			return;
		}

		// Don't allow pause menu here
		Game::HazeGameInstance.ClosePauseMenu();

		// We might be in a menu lobby (accepted an invite through OS)
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && !Lobby.HasGameStarted())
		{
			CloseWidget();
			return;
		}

		if (IsBusy())
		{
			Spinner.Visibility = ESlateVisibility::Visible;
			PurchaseButton.Visibility = ESlateVisibility::Collapsed;
			ReturnButton.Visibility = ESlateVisibility::Collapsed;
		}
		else
		{
			Spinner.Visibility = ESlateVisibility::Collapsed;
			PurchaseButton.Visibility = ESlateVisibility::Visible;
			ReturnButton.Visibility = ESlateVisibility::Visible;
		}

		if (!IsMessageDialogShown())
			Widget::SetAllPlayerUIFocusBeneathParent(this);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry Geom, FFocusEvent Event)
	{
		return FEventReply::Handled().SetUserFocus(PurchaseButton, Event.Cause);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		return FEventReply::Handled();
	}
};

local void ConsoleTrialUpsell(const TArray<FString>& Args)
{
#if EDITOR
	TSubclassOf<UHazeUserWidget> WidgetClass = Cast<UClass>(LoadObject(nullptr, "/Game/GUI/MainMenu/WBP_TrialUpsellWidget.WBP_TrialUpsellWidget_C"));
	Game::HazeGameInstance.TriggerTrialUpsell(WidgetClass);
#endif
}

namespace DemoUpsell
{

bool NeedsUpsell()
{
	if (Game::HazeGameInstance == nullptr)
		return false;
	return Game::HazeGameInstance.IsTrialUpsellNeeded();
}

UFUNCTION()
void ReachedFriendsPassDemoBoundary(TSubclassOf<UHazeUserWidget> TrialUpsellWidget)
{
	Game::HazeGameInstance.TriggerTrialUpsell(TrialUpsellWidget);
}

UFUNCTION(BlueprintPure)
bool IsDemoUpsellActive()
{
	return Game::HazeGameInstance.bTrialUpsellActive;
}

}