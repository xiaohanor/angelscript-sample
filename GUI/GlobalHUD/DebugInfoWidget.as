const FConsoleVariable CVar_ShowLatestSave("Haze.ShowLatestSave", 0);
const FConsoleVariable CVar_ShowPlayingCutscene("Haze.ShowPlayingCutscene", 0);

class UDebugInfoWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UWidget RootPanel;
	UPROPERTY(BindWidget)
	UTextBlock TextWidget;
	UPROPERTY(BindWidget)
	UWidget FrameNumberContainer;
	UPROPERTY(BindWidget)
	UTextBlock FrameNumber;
	UPROPERTY(BindWidget)
	UTextBlock LatestSaveMessage;

	FString PrevProgressText;
	FName PrevProgressPoint;

	bool bShown = true;

	float UpdateTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UpdateText();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		UpdateTimer -= DeltaTime;
		if (UpdateTimer <= 0.0)
		{
			UpdateTimer = 3.0;
			UpdateText();
		}

		bool bShouldShow = Debug::AreOnScreenMessagesEnabled();
		if (bShown != bShouldShow)
		{
			bShown = !bShown;
			if (bShown)
				RootPanel.SetVisibility(ESlateVisibility::HitTestInvisible);
			else
				RootPanel.SetVisibility(ESlateVisibility::Collapsed);
		}

#if !EDITOR
		auto TemporalLog = UHazeTemporalLog::Get();
		if (TemporalLog != nullptr)
		{
			FrameNumber.SetText(FText::FromString(f"{TemporalLog.GameFrameCounterModuloStart :0>4}"));
			FrameNumberContainer.SetVisibility(ESlateVisibility::HitTestInvisible);
		}
		else
		{
			FrameNumberContainer.SetVisibility(ESlateVisibility::Collapsed);
		}
#endif

#if TEST
		if (CVar_ShowLatestSave.GetInt() != 0 || CVar_ShowPlayingCutscene.GetInt() != 0)
		{
			FString InfoText;

			if (CVar_ShowPlayingCutscene.GetInt() != 0)
			{
				if (Game::Mio != nullptr && Game::Mio.ActiveLevelSequenceActor != nullptr)
					InfoText += f"Cutscene:\n{Game::Mio.ActiveLevelSequenceActor.Sequence.Name}\n\n";
				else if (Game::Zoe != nullptr && Game::Zoe.ActiveLevelSequenceActor != nullptr)
					InfoText += f"Cutscene:\n{Game::Zoe.ActiveLevelSequenceActor.Sequence.Name}\n\n";
				else
					InfoText += f"Cutscene:\nNone\n\n";
			}

			if (CVar_ShowLatestSave.GetInt() != 0)
			{
				FHazeProgressPointRef ChapterRef;
				FHazeProgressPointRef ProgressPointRef;
				if (Save::GetSaveToRestart(ChapterRef, ProgressPointRef))
				{
					FString PointName = ProgressPointRef.Name;
					FString LevelName = Progress::GetShortLevelName(Progress::GetLevelGroup(ProgressPointRef.InLevel));

					auto ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();
					FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(ChapterRef);
					InfoText += f"Latest Save:\n{PointName} ({LevelName})\n\nLatest Chapter:\n{Chapter.Name}\n\n";
				}
				else
				{
					InfoText += f"Latest Save:\nNone\n\n";
				}

				FHazeProgressPointRef SkipRef;
				if (Save::GetSkipNextSection(SkipRef))
				{
					FString PointName = SkipRef.Name;
					FString LevelName = Progress::GetShortLevelName(Progress::GetLevelGroup(SkipRef.InLevel));

					InfoText += f"Skip Target:\n{PointName} ({LevelName})\n\n";
				}
				else
				{
					InfoText += f"Skip Target:\nNone\n\n";
				}
			}

			LatestSaveMessage.Text = FText::FromString(InfoText);
			LatestSaveMessage.SetVisibility(ESlateVisibility::HitTestInvisible);
		}
		else
		{
			LatestSaveMessage.SetVisibility(ESlateVisibility::Collapsed);
		}
#endif
	}

	void UpdateText()
	{
		FString Text;

		if (Network::IsGameNetworked())
		{
			Text += "Ping: ";
			Text += int(Network::PingRoundtripSeconds * 1000.0);
			float Loss = Debug::GetConnectionPacketLoss();
			if (Loss > 0.001)
			{
				Text += f"ms | Loss: {Loss * 100.0 :.1}%\n";
			}
			else
			{
				Text += "ms\n";
			}
		}

		auto ProgressRef = Progress::GetProgressPointRefFromID(Progress::DebugGetActiveProgressPoint());
		if (ProgressRef.Name.Len() != 0)
		{
			Text += f"{ProgressRef.Name} ({Progress::GetLevelGroup(Progress::GetShortLevelName(ProgressRef.InLevel))})";
			Text += "\n";
		}

		FHazeBuildInfo BuildInfo  = Game::GetHazeBuildVersionStaticsDev();
		if (BuildInfo.Build == "0")
		{
			Text += "Local Build";
		}
		else
		{
			Text += f"{Online::GetOnlinePlatformName()} build {BuildInfo.Build} on {BuildInfo.CodeHash.Mid(0, 6)}, CL{BuildInfo.DataCL}";
		}

		TextWidget.SetText(FText::FromString(Text));
	}
};