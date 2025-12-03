
const FConsoleVariable CVar_SubtitlesEnabled("Haze.SubtitlesEnabled", 2);
const FConsoleVariable CVar_CaptionsEnabled("Haze.ClosedCaptionsEnabled", 0);
const FConsoleVariable CVar_ZoeGameplaySubtitles("Haze.ZoeGameplaySubtitles", 1);
const FConsoleVariable CVar_MioGameplaySubtitles("Haze.MioGameplaySubtitles", 1);
const FConsoleVariable CVar_SubtitleBackground("Haze.SubtitleBackground", 0);

struct FActiveSubtitle
{
	FHazeSubtitleLine Line;
	float RemainingDuration;
	FInstigator Instigator;
	UHazeSubtitleAsset FromAsset;
	EHazeSubtitlePriority Priority;
};

UCLASS(Abstract)
class USubtitleLineWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazeSubtitleLine ActiveLine;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EHazeSubtitlePriority ActivePriority;

	UPROPERTY(Meta = (BindWidget))
	UBorder BackgroundBox;

	UPROPERTY(Meta = (BindWidget))
	UTextBlock SubtitleText;

	UPROPERTY()
	bool bSubtitleBackground = false;

	const int32 DefaultFontSize = 18;
	const int32 LargeFontSize = 22;

	void UpdateLine()
	{
		SubtitleText.Text = FilterSubtitleText(ActiveLine.Text);

		const FLinearColor TextColor = ActiveLine.bDisplayAsTemp ? FLinearColor::Yellow : FLinearColor::White;
		SubtitleText.SetColorAndOpacity(TextColor);

		const FName WantedTypeface = ShouldBeItalic() ? n"Italic" : NAME_None;
		const int32 WantedFontSize = ShouldUseLargeFont() ? LargeFontSize : DefaultFontSize;
		if (SubtitleText.Font.TypefaceFontName != WantedTypeface || SubtitleText.Font.Size != WantedFontSize)
		{
			FSlateFontInfo Font = SubtitleText.Font;
			Font.TypefaceFontName = WantedTypeface;
			Font.Size = WantedFontSize;
			SubtitleText.SetFont(Font);
		}

		// Show the black background for the subtitles if we want to
		if (bSubtitleBackground && !SubtitleText.Text.IsEmpty())
			BackgroundBox.SetVisibility(ESlateVisibility::HitTestInvisible);
		else
			BackgroundBox.SetVisibility(ESlateVisibility::Hidden);
	}

	UFUNCTION(BlueprintPure)
	bool ShouldBeItalic()
	{
		// Never italicize in fullscreen
		if (SceneView::IsFullScreen())
			return false;

		// Skip italics for some locs
		if (ShouldIgnoreItalics())
			return false;

		// Italicize text that the other player said
		if (Player != nullptr)
		{
			if (Player.IsZoe())
			{
				if (ActiveLine.SourceTag == n"MioBark")
					return true;
			}
			else
			{
				if (ActiveLine.SourceTag == n"ZoeBark")
					return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldUseLargeFont()
	{
#if EDITOR
		const FName CurrentLanguage = Editor::GetGameLocalizationPreviewLanguage();
#else
		const FName CurrentLanguage = FName(Internationalization::GetCurrentLanguage());
#endif

		const bool bNeedsLargeFont = CurrentLanguage == n"ko-KR" || CurrentLanguage == n"zh-Hant" || CurrentLanguage == n"zh-Hans";

		return bNeedsLargeFont;
	}

	// Filter the given subtitle to display the correct subtitles based on game settings.
	UFUNCTION(BlueprintPure)
	FText FilterSubtitleText(FText Subtitle) const
	{
		if (Subtitle.IsEmpty())
			return Subtitle;

		TArray<FString> Lines;
		Subtitle.ToString().ParseIntoArray(Lines, "\n", false);

		FString OutStr;
		bool bIsCC = false;
		bool bIsNoCC = false;

		for (FString& Line : Lines)
		{
			FString StartTrimmedLine = Line.TrimStart();
			if (StartTrimmedLine.StartsWith("CC:"))
			{
				bIsCC = true;
				bIsNoCC = false;
				Line = StartTrimmedLine.RightChop(3).TrimStart();
			}
			else if (StartTrimmedLine.StartsWith("NO_CC:"))
			{
				bIsCC = false;
				bIsNoCC = true;
				Line = StartTrimmedLine.RightChop(6).TrimStart();
			}

			if (CVar_CaptionsEnabled.GetInt() == 1)
			{
				if (bIsNoCC)
					continue;
			}
			else
			{
				if (bIsCC)
					continue;
			}

			if (OutStr.Len() != 0)
				OutStr += "\n";
			OutStr += Line;
		}

		return FText::FromString(OutStr);
	}

	private bool ShouldIgnoreItalics() const
	{
#if EDITOR
		const FName CurrentLanguage = Editor::GetGameLocalizationPreviewLanguage();
#else
		const FName CurrentLanguage = FName(Internationalization::GetCurrentLanguage());
#endif

		const bool bIsAsianLanguage = CurrentLanguage == n"ja-JP" || CurrentLanguage == n"ko-KR" || CurrentLanguage == n"zh-Hant" || CurrentLanguage == n"zh-Hans";

		return bIsAsianLanguage;
	}
}

UCLASS(Abstract)
class USubtitleWidget : UHazeUserWidget
{
	UPROPERTY(Meta = (BindWidget))
	UWidget MainCanvas;

	UPROPERTY(Meta = (BindWidget))
	UOverlay TextContainer;

	UPROPERTY(Meta = (BindWidget))
	UVerticalBox SubtitlesBox;

	USubtitleManagerComponent SubtitleComp;

	TArray<USubtitleLineWidget> SubtitleLineWidgets;

	UPROPERTY()
	bool bSubtitleBackground = false;

	UPROPERTY()
	bool bFullscreenSubtitles = false;

	private const float DefaultSubtitileOffset = -50.0;
	private const float CancelSubtitleOffset = -100.0;
	private const float TutorialSubtitleOffset = -260.0;

	private const float RemoveDelayTime = 0.3;
	float LastSeenCancel = -1.0;
	float LastSeenTutorial = -1.0;

	float LastTutorialOffset = 0;
	float LastTutorialOffsetTime = -1.0;

	void Show()
	{
		SubtitleLineWidgets.Reset();

		for (UWidget BoxWidget : SubtitlesBox.AllChildren)
		{
			USubtitleLineWidget SubtitleLineWidget = Cast<USubtitleLineWidget>(BoxWidget);
			SubtitleLineWidget.ActiveLine = FHazeSubtitleLine();
			SubtitleLineWidgets.Add(SubtitleLineWidget);
		}
	}

	void UpdateActiveLines()
	{
		// Get Subtitle lines to show
		TArray<FActiveSubtitle> ShownSubtitles;
		SubtitleComp.GetShownSubtitles(ShownSubtitles);

		// Update subtitle line text
		int WidgetIndex = SubtitleLineWidgets.Num() - 1;
		int SortedLineIndex = ShownSubtitles.Num() - 1;
		while (WidgetIndex >= 0 && SortedLineIndex >= 0)
		{
			if (!ShownSubtitles[SortedLineIndex].Line.Text.IdenticalTo(SubtitleLineWidgets[WidgetIndex].ActiveLine.Text))
			{
				SubtitleLineWidgets[WidgetIndex].ActiveLine = ShownSubtitles[SortedLineIndex].Line;
				SubtitleLineWidgets[WidgetIndex].ActivePriority = ShownSubtitles[SortedLineIndex].Priority;
			}

			WidgetIndex--;
			SortedLineIndex--;
		}

		// Reset unused lines
		while (WidgetIndex >= 0)
		{
			if (!SubtitleLineWidgets[WidgetIndex].ActiveLine.Text.IsEmpty())
			{
				SubtitleLineWidgets[WidgetIndex].ActiveLine = FHazeSubtitleLine();
			}
			WidgetIndex--;
		}

		// Move the subtitles up a bit
		const float SubtitleOffset = UpdateSubtitleOffset();
		FVector2D SubtitleTranslation = FVector2D(0.0, SubtitleOffset);
		TextContainer.SetRenderTranslation(SubtitleTranslation);

		// Update subtitle line widgets
		for (USubtitleLineWidget SubtileLine : SubtitleLineWidgets)
		{
			SubtileLine.UpdateLine();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTIme)
	{
		bool bForceUpdate = false;

		// Update the position of the main widget to follow the player's view rect
		if (MainCanvas != nullptr)
		{
			FVector2D GeomSize = Geom.LocalSize;
			UCanvasPanelSlot MainSlot = Cast<UCanvasPanelSlot>(MainCanvas.Slot);

			bool bForcedFullScreen = false;

			// Menu subtitles are always fullscreen
			if (Player == nullptr)
				bForcedFullScreen = true;

			if (SubtitleComp.IsForcedFullscreen())
				bForcedFullScreen = true;

			// If both players are in a splitscreen cutscene, the subtitles should be fullscreen
			for (USubtitleLineWidget SubtileLine : SubtitleLineWidgets)
			{
				if (!SubtileLine.ActiveLine.Text.IsEmpty() && SubtileLine.ActivePriority == EHazeSubtitlePriority::Cutscene)
				{
					if (Player != nullptr && Player.bIsControlledByCutscene && Player.OtherPlayer.bIsControlledByCutscene && Player.ActiveLevelSequenceActor == Player.OtherPlayer.ActiveLevelSequenceActor)
					{
						bForcedFullScreen = true;
						break;
					}
				}
			}

			if (bForcedFullScreen)
			{
				MainSlot.SetPosition(FVector2D(0.0, 0.0));
				MainSlot.SetSize(GeomSize);
				MainCanvas.SetVisibility(ESlateVisibility::HitTestInvisible);

				if (!bFullscreenSubtitles)
				{
					bFullscreenSubtitles = true;
					bForceUpdate = true;
				}
			}
			else if (SubtitleComp.IsForcedHidden())
			{
				MainCanvas.SetVisibility(ESlateVisibility::Hidden);
			}
			else
			{
				FVector2D MinPos;
				FVector2D MaxPos;
				SceneView::GetUnletterboxedPercentageScreenRectFor(Player, MinPos, MaxPos);

				MainSlot.SetPosition(FVector2D(MinPos.X * GeomSize.X, MinPos.Y * GeomSize.Y));
				MainSlot.SetSize(FVector2D((MaxPos.X - MinPos.X) * GeomSize.X, (MaxPos.Y - MinPos.Y) * GeomSize.Y));

				if (MaxPos.X - MinPos.X < 0.25)
					MainCanvas.SetVisibility(ESlateVisibility::Hidden);
				else if (MaxPos.Y - MinPos.Y < 0.25)
					MainCanvas.SetVisibility(ESlateVisibility::Hidden);
				else
					MainCanvas.SetVisibility(ESlateVisibility::HitTestInvisible);

				bool bIsFullscreen = SceneView::IsFullScreen();
				if (bIsFullscreen != bFullscreenSubtitles)
				{
					bFullscreenSubtitles = bIsFullscreen;
					bForceUpdate = true;
				}
			}
		}

		// Update whether to show subtitle background
		bool bShowBackground = CVar_SubtitleBackground.GetInt() != 0;
		if (bShowBackground != bSubtitleBackground)
		{
			bSubtitleBackground = bShowBackground;
			bForceUpdate = true;

			for (USubtitleLineWidget LineWidget : SubtitleLineWidgets)
			{
				LineWidget.bSubtitleBackground = bSubtitleBackground;
			}
		}

		if (bForceUpdate)
		{
			UpdateActiveLines();
		}
	}

	private float UpdateSubtitleOffset()
	{
		// Move the subtitles further up if there is a cancel prompt or tutorial
		UTutorialComponent TutComp = UTutorialComponent::Get(SubtitleComp.Owner);

		if (TutComp != nullptr)
		{
			int32 NumShownSubtitles = 0;
			for (const USubtitleLineWidget Sub : SubtitleLineWidgets)
			{
				if (!Sub.ActiveLine.Text.IsEmpty())
				{
					NumShownSubtitles += 1;
				}
			}

			bool bShowingOtherCancel = false;
			if (bFullscreenSubtitles)
			{
				auto OtherPlayer = Cast<AHazePlayerCharacter>(SubtitleComp.Owner).OtherPlayer;
				UTutorialComponent OtherTutComp = UTutorialComponent::Get(OtherPlayer);
				if (OtherTutComp != nullptr)
				{
					bShowingOtherCancel = OtherTutComp.CancelPrompt != nullptr;
				}
			}

			const bool bShowingCancel = TutComp.CancelPrompt != nullptr || bShowingOtherCancel;
			const bool bShowingTutorial = TutComp.ActiveTutorials.Num() > 0 || TutComp.ActiveChains.Num() > 0;
			const bool bMultipleLines = NumShownSubtitles > 1;
			const bool bForceTutorialOffset = SubtitleComp.IsForceTutorialSubtitleOffset();

			if (bShowingTutorial && (bShowingCancel || bMultipleLines))
				LastSeenTutorial = Time::GameTimeSeconds;

			if (bForceTutorialOffset)
			{
				LastSeenTutorial = Time::GameTimeSeconds;

				// Only use the TutorialScreenSpaceOffset when we are forcing the tutorial offset
				const float TutCompOffset = TutComp.TutorialScreenSpaceOffset.Get();
				if (!Math::IsNearlyZero(TutCompOffset))
				{
					LastTutorialOffset = TutCompOffset;
					LastTutorialOffsetTime = Time::GameTimeSeconds;
				}
			}

			if (bShowingCancel)
				LastSeenCancel = Time::GameTimeSeconds;

			if (Time::GetGameTimeSince(LastSeenTutorial) < RemoveDelayTime)
			{
				if (Time::GetGameTimeSince(LastTutorialOffsetTime) < RemoveDelayTime)
				{
					return TutorialSubtitleOffset + LastTutorialOffset;
				}
				return TutorialSubtitleOffset;
			}

			if (Time::GetGameTimeSince(LastSeenCancel) < RemoveDelayTime)
				return CancelSubtitleOffset;
		}

		return DefaultSubtitileOffset;
	}
};

class USubtitleManagerComponent : UHazeSubtitleComponentBase
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	TSubclassOf<USubtitleWidget> SubtitleWidget;

	private TArray<FActiveSubtitle> SubtitleSlots;
	private bool bSubtitlesActive = false;
	private USubtitleWidget Widget;
	private float LastSubtitleShownTime = 0.0;
	private AHazePlayerCharacter PlayerOwner;

	private TArray<FInstigator> ForceFullscreenInstigators;
	private TArray<FInstigator> ForceHideSubtitleInstigators;
	private TArray<FInstigator> ForceTutorialSubtitleOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SubtitleSlots.Reset();
		SubtitleSlots.Add(FActiveSubtitle());
		SubtitleSlots.Add(FActiveSubtitle());

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (Widget != nullptr)
			Widget::RemoveFullscreenWidget(Widget);
	}

	private bool AddSubtitle(const FActiveSubtitle& Subtitle)
	{
		bool bHasFreeSlot = false;
		for (int i = 0; i < SubtitleSlots.Num(); ++i)
		{
			if (SubtitleSlots[i].Line.Text.IsEmpty())
			{
				bHasFreeSlot = true;
				continue;
			}

			if (i > 0)
			{
				if (bHasFreeSlot)
				{
					SubtitleSlots[i - 1] = SubtitleSlots[i];
					continue;
				}

				if (SubtitleSlots[i - 1].Priority <= SubtitleSlots[i].Priority)
				{
					SubtitleSlots[i - 1] = SubtitleSlots[i];
					bHasFreeSlot = true;
					continue;
				}
			}
		}

		if (bHasFreeSlot)
		{
			SubtitleSlots[SubtitleSlots.Num() - 1] = Subtitle;
			return true;
		}

		if (SubtitleSlots[SubtitleSlots.Num() - 1].Priority <= Subtitle.Priority)
		{
			SubtitleSlots[SubtitleSlots.Num() - 1] = Subtitle;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ShowSubtitle(const FHazeSubtitleLine& Line, float Duration, FInstigator Instigator, EHazeSubtitlePriority Priority = EHazeSubtitlePriority::Medium)
	{
		FActiveSubtitle Subtitle;
		Subtitle.Line = Line;
		Subtitle.RemainingDuration = Duration;
		Subtitle.Instigator = Instigator;
		Subtitle.Priority = Priority;

		if (AddSubtitle(Subtitle))
		{
			ActivateSubtitles();
			LastSubtitleShownTime = Time::GetGameTimeSeconds();
		}
	}

	UFUNCTION(BlueprintOverride)
	void ShowSubtitlesFromAsset(UHazeSubtitleAsset Asset, float TimeInAsset, FInstigator Instigator, EHazeSubtitlePriority Priority = EHazeSubtitlePriority::Cutscene)
	{
		// Remove any lines that were already added by this asset
		ClearSubtitlesByAsset(Asset);

		// Add lines that match the current specified time
		for (const FHazeSubtitleTiming& Timing : Asset.Lines)
		{
			if (Timing.StartTime > TimeInAsset)
				continue;
			if (Timing.EndTime <= TimeInAsset)
				continue;

			FActiveSubtitle Subtitle;
			Subtitle.Line = Timing.Line;
			Subtitle.RemainingDuration = 0.0;
			Subtitle.Instigator = Instigator;
			Subtitle.FromAsset = Asset;
			Subtitle.Priority = Priority;

			if (AddSubtitle(Subtitle))
			{
				ActivateSubtitles();
				LastSubtitleShownTime = Time::GetGameTimeSeconds();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void ClearSubtitlesByInstigator(FInstigator Instigator)
	{
		for (int i = 0; i < SubtitleSlots.Num(); ++i)
		{
			if (SubtitleSlots[i].Instigator == Instigator)
				SubtitleSlots[i] = FActiveSubtitle();
		}
	}

	UFUNCTION(BlueprintOverride)
	void ClearSubtitlesByAsset(UHazeSubtitleAsset Asset)
	{
		for (int i = 0; i < SubtitleSlots.Num(); ++i)
		{
			if (SubtitleSlots[i].FromAsset == Asset)
				SubtitleSlots[i] = FActiveSubtitle();
		}
	}

	bool GetShownSubtitles(TArray<FActiveSubtitle>& OurSortedSubtitles)
	{
		if (CVar_SubtitlesEnabled.GetInt() == 0)
			return false;

		bool bHasSubtitle = false;
		for (int i = 0; i < SubtitleSlots.Num(); ++i)
		{
			OurSortedSubtitles.Add(SubtitleSlots[i]);
			if (!SubtitleSlots[i].Line.Text.IsEmpty())
				bHasSubtitle = true;
		}

		return bHasSubtitle;
	}

	private void ActivateSubtitles()
	{
		if (bSubtitlesActive)
			return;
		bSubtitlesActive = true;
		SetComponentTickEnabled(true);

		if (Widget == nullptr)
		{
			Widget = Widget::AddFullscreenWidget(SubtitleWidget, EHazeWidgetLayer::Overlay);
			if (PlayerOwner != nullptr)
				Widget.OverrideWidgetPlayer(PlayerOwner);
		}
		else
		{
			Widget::AddExistingFullscreenWidget(Widget, EHazeWidgetLayer::Overlay);
		}

		Widget.SetWidgetPersistent(true);
		Widget.SubtitleComp = this;
		Widget.Show();
		Widget.UpdateActiveLines();
	}

	private void DeactivateSubtitles()
	{
		if (!bSubtitlesActive)
			return;
		bSubtitlesActive = false;
		SetComponentTickEnabled(false);

		if (Widget != nullptr)
			Widget::RemoveFullscreenWidget(Widget);
	}

	bool IsForcedFullscreen() const
	{
		return ForceFullscreenInstigators.Num() > 0;
	}

	void AddForceFullscreenInstigator(FInstigator Instigator)
	{
		ForceFullscreenInstigators.AddUnique(Instigator);
	}

	void RemoveForceFullscreenInstigator(FInstigator Instigator)
	{
		ForceFullscreenInstigators.Remove(Instigator);
	}

	bool IsForcedHidden() const
	{
		return ForceHideSubtitleInstigators.Num() > 0;
	}

	void AddForceHiddenInstigator(FInstigator Instigator)
	{
		ForceHideSubtitleInstigators.AddUnique(Instigator);
	}

	void RemoveForceHiddenInstigator(FInstigator Instigator)
	{
		ForceHideSubtitleInstigators.Remove(Instigator);
	}

	bool IsForceTutorialSubtitleOffset() const
	{
		return ForceTutorialSubtitleOffset.Num() > 0;
	}

	void AddForceTutorialSubtitleOffsetInstigator(FInstigator Instigator)
	{
		ForceTutorialSubtitleOffset.AddUnique(Instigator);
	}

	void RemoveForceTutorialSubtitleOffsetInstigator(FInstigator Instigator)
	{
		ForceTutorialSubtitleOffset.Remove(Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Update remaining time on any added subtitles
		int NumActiveSubtitles = 0;
		for (int i = 0; i < SubtitleSlots.Num(); ++i)
		{
			if (SubtitleSlots[i].RemainingDuration > 0.0)
			{
				SubtitleSlots[i].RemainingDuration -= DeltaTime;
				if (SubtitleSlots[i].RemainingDuration <= 0.0)
					SubtitleSlots[i] = FActiveSubtitle();
			}

			if (!SubtitleSlots[i].Line.Text.IsEmpty())
				NumActiveSubtitles++;
		}

		if (NumActiveSubtitles == 0)
		{
			if (Time::GetGameTimeSince(LastSubtitleShownTime) > 2.0)
				DeactivateSubtitles();
		}
		else
		{
			LastSubtitleShownTime = Time::GetGameTimeSeconds();
		}

		if (bSubtitlesActive && Widget != nullptr)
		{
			Widget.UpdateActiveLines();
		}
	}
};
