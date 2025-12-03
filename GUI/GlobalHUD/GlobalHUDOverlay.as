const FConsoleVariable CVar_HideSavingWidget("Haze.HideSavingWidget", 0);

class UGlobalHUDOverlayWidget : UHazeUserWidget
{
	bool bStartedSaving = false;
	float LastSaveGameTime = 0.0;

	bool bHasGameStartedProper = false;
	float GameStartedTimer = 0.0;

	UPROPERTY(BindWidget)
	USpinnerWidget SaveSpinner;

	UPROPERTY()
	UIdentityEngagementWidget Engagement_Menu;
	UPROPERTY()
	UIdentityEngagementWidget Engagement_Mio;
	UPROPERTY()
	UIdentityEngagementWidget Engagement_Zoe;

	UPROPERTY()
	UWidget MemoryWarningWidget;

	UPROPERTY(Category="Sounds")
	FSoundDefReference SoundDefReference;

	TInstigated<UMaterialInterface> SaveSpinnerMaterial;

	bool bAddedSoundDef = false;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		SaveSpinnerMaterial.SetDefaultValue(Cast<UMaterialInterface>(SaveSpinner.Image.GetDynamicMaterial()));
		SetWidgetZOrderInLayer(801);
	}

	void AddOrRemoveSoundDefByVisibility(bool bVisibleUI)
	{
		if (bVisibleUI == bAddedSoundDef)
			return;

		bAddedSoundDef = bVisibleUI;

		if (bVisibleUI)
			Menu::AttachSoundDef(SoundDefReference, this);
		else
			Menu::RemoveSoundDef(SoundDefReference, this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartedSaving() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnFinishedSaving() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		auto Lobby = Lobby::GetLobby();

		/** Update the save indicator **/
		if (!bHasGameStartedProper)
		{
			if (!Game::IsInLoadingScreen() && Lobby != nullptr && Lobby.HasGameStarted())
			{
				GameStartedTimer += Timer;
				if (GameStartedTimer > 4.0)
					bHasGameStartedProper = true;
			}
		}
		else
		{
			if (Lobby == nullptr || !Lobby.HasGameStarted() || Save::HasRecentlyRestarted())
			{
				bHasGameStartedProper = false;
				GameStartedTimer = 0.0;
			}
		}

		if (!bStartedSaving)
		{
			// Start saving when we've recently saved at a progress point
			if (Save::HasRecentlySaved() && bHasGameStartedProper && !CVar_HideSavingWidget.GetBool())
			{
				if (Time::RealTimeSeconds > LastSaveGameTime)
				{
					bStartedSaving = true;
					SaveSpinner.Image.SetBrushFromMaterial(SaveSpinnerMaterial.Get());
					BP_OnStartedSaving();
					LastSaveGameTime = Time::RealTimeSeconds;
				}
			}
		}
		else
		{
			// Finish the save once no profiles are dirty anymore
			if (!IsAnyProfileDirty() && Time::RealTimeSeconds > LastSaveGameTime + 1.0)
			{
				bStartedSaving = false;
				BP_OnFinishedSaving();
				LastSaveGameTime = Time::RealTimeSeconds + 4.0;
			}
		}

		/** Update identity engagement UI **/
		if (Lobby == nullptr || !Lobby.HasGameStarted())
		{
			if (Online::PrimaryIdentity != nullptr && Online::PrimaryIdentity.Engagement != EHazeIdentityEngagement::Engaged)
			{
				Engagement_Menu.Identity = Online::PrimaryIdentity;
				Engagement_Menu.SetVisibility(ESlateVisibility::HitTestInvisible);
			}
			else
			{
				Engagement_Menu.SetVisibility(ESlateVisibility::Collapsed);
			}

			Engagement_Mio.SetVisibility(ESlateVisibility::Collapsed);
			Engagement_Zoe.SetVisibility(ESlateVisibility::Collapsed);
		}
		else
		{
			for (auto CheckPlayer : Game::Players)
			{
				auto Identity = Lobby::GetIdentityForPlayer(CheckPlayer);
				UIdentityEngagementWidget Widget = CheckPlayer.IsMio() ? Engagement_Mio : Engagement_Zoe;
				if (Identity != nullptr && Identity.Engagement != EHazeIdentityEngagement::Engaged)
				{
					Widget.Identity = Identity;
					Widget.OverrideWidgetPlayer(CheckPlayer);
					Widget.SetVisibility(ESlateVisibility::HitTestInvisible);
				}
				else
				{
					Widget.SetVisibility(ESlateVisibility::Collapsed);
				}
			}

			Engagement_Menu.SetVisibility(ESlateVisibility::Collapsed);
		}

		// Adds or removes SD, depending on any visible ui.
		AddOrRemoveSoundDefByVisibility(Engagement_Menu.IsVisible() || Engagement_Mio.IsVisible() || Engagement_Zoe.IsVisible());

#if TEST
		if (MemoryWarningWidget != nullptr)
		{
			MemoryWarningWidget.SetVisibility(
				Debug::ShouldWarnMemoryBudget() && !Debug::IsUXTestBuild()
					? ESlateVisibility::HitTestInvisible
					: ESlateVisibility::Collapsed
			);
		}
#endif
	}

	bool IsAnyProfileDirty()
	{
		for (auto Profile : Lobby::GetIdentitiesInGame())
		{
			if (!Profile.IsLocal())
				continue;
			if (Profile::IsProfileDirty(Profile))
				return true;
		}
		return false;
	}
};

class UIdentityEngagementWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	UHazePlayerIdentity Identity;
};