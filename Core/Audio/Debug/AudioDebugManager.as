struct FAudioDebugDrawHelper
{
	UHazeImmediateWidget ImmediateWidget;
	bool bIsMio = false;

	bool bHasContent = false;
	bool bHasBegin = false;

	bool IsPlayerVisible() const
	{
		#if EDITOR
		if (!Editor::IsPlaying())
		{
			return false;
		}
		#endif

		if (SceneView::GetPlayerViewSizePercentage(Game::GetPlayer(bIsMio ? EHazePlayer::Mio : EHazePlayer::Zoe)) > 0)
			return true;

		return false;
	}

	bool IsVisible() { return ImmediateWidget != nullptr && ImmediateWidget.Drawer != nullptr && ImmediateWidget.Drawer.IsVisible() && IsPlayerVisible(); }
	bool HasBegun() { return bHasBegin; }

	FHazeImmediateSectionHandle Begin()
	{
		bHasBegin = true;
		auto Section = ImmediateWidget.Drawer.Begin();
		if (bIsMio)
		{
			Section.Spacer(75);
		}
		else
		{
			Section.Spacer(25);
		}

		return Section;
	}

	void End()
	{
		bHasBegin = false;
		ImmediateWidget.Drawer.End();
	}

	void Reset()
	{
		if (!IsVisible())
			return;

		Begin();
		End();
	}
}

class UAudioDebugManager : UHazeAudioDebugManager
{
	access InternalAudioDebug = private, UHazeAudioDevMenu, UAudioDebugDelay;

	UPROPERTY()
	TSubclassOf<UAudioGraphWidget> GraphWidget;

	UPROPERTY()
	TSubclassOf<UAudioViewportWidget> ViewportWidget;

	UPROPERTY()
	TSubclassOf<UVoxViewportOverlayWidget> VoxViewportOverlayWidgetClass;

	private UHazeImmediateWidget MiosImmediateWidget;
	private UHazeImmediateWidget ZoesImmediateWidget;

	private FAudioDebugDrawHelper MiosDrawHelper;
	private FAudioDebugDrawHelper ZoesDrawHelper;

	private UVoxViewportOverlayWidget VoxViewportOverlayWidget;

	private bool bPrintAllRTPCS = false;
	private TMap<UHazeAudioComponent, bool> PrintRTPCs;

	access:InternalAudioDebug
	TArray<FString> ReflectionDirectionPrettyNames;

	// Temp until fixed in c++
	bool bTempHasSetup = false;

	access:InternalAudioDebug
	TArray<UAudioDebugTypeHandler> DebugTypeHandlers;
	default DebugTypeHandlers.SetNum(EHazeAudioDebugType::NumOfTypes);

	UHazeAudioDevMenu DevMenu = nullptr;
	UHazeAudioDevMenuConfig MenuDebugConfig;
	UHazeAudioDebugConfig DebugConfig;

	TArray<USpotSoundComponent> SpotSounds;

	void RegisterSpot(USpotSoundComponent SpotSound)
	{
		SpotSounds.Add(SpotSound);
	}

	void UnregisterSpot(USpotSoundComponent SpotSound)
	{
		SpotSounds.Remove(SpotSound);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MenuDebugConfig = AudioDebug::GetMenuConfig();
		DebugConfig = AudioDebug::GetConfig();

		const auto Classes = UClass::GetAllSubclassesOf(UAudioDebugTypeHandler);
		for (UClass HandlerClass: Classes)
		{
			auto DebugHandler = AudioDebug::GetHandlerOfType(HandlerClass);
			if (DebugHandler.Type() >= EHazeAudioDebugType::NumOfTypes)
				continue;

			if (DebugHandler != nullptr)
				DebugTypeHandlers[DebugHandler.Type()] = DebugHandler;
			
			// If the handler requires some sort of setup when the debugmanager has done it's setup. (I.e. started a new game instance)
			DebugHandler.Setup(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{
		for (auto Handler : DebugTypeHandlers)
		{
			if (Handler == nullptr)
				continue;

			const auto TypeIndex = int(Handler.Type());
			Handler.bIsWorldDebugEnabled = AudioDebug::IsEnabled(EDebugAudioWorldVisualization(TypeIndex));

			if (Handler.DebugEnabled())
			{
				// TODO : Go through all the debug handlers and see if this SHOULD be used on more places.
				Handler.Shutdown();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	TSubclassOf<UHazeAudioGraphWidget> GetGraphWidgetClass()
	{
		return GraphWidget;
	}

	UFUNCTION(BlueprintOverride)
	TSubclassOf<UHazeUserWidget> GetOverlayWidgetClass()
	{
		return ViewportWidget;
	}

	FAudioDebugFilter& GetWorldFilters() property
	{
		return MenuDebugConfig.WorldFilter;
	}

	FAudioDebugFilter& GetViewportFilters() property
	{
		return MenuDebugConfig.ViewFilter;
	}

	FAudioDebugMiscFlags& GetMiscFlags() property
	{
		return MenuDebugConfig.MiscFlags;
	}

	TArray<UHazeAudioComponent> GetComps()
	{
		return GetRegisteredComponents();
	}

	const FAudioDebugFilter& GetWorldFilters() const property
	{
		return MenuDebugConfig.WorldFilter;
	}

	const FAudioDebugFilter& GetViewportFilters() const property
	{
		return MenuDebugConfig.ViewFilter;
	}

	bool IsFilterEmpty(bool bWorldFilter, EDebugAudioFilter FilterType) const
	{
		if (bWorldFilter)
			return WorldFilters.GetFilterText(FilterType).IsEmpty();

		return ViewportFilters.GetFilterText(FilterType).IsEmpty();
	}

	bool IsFiltered(const FString& InName, bool bWorldFilter, EDebugAudioFilter FilterType) const
	{
		if (bWorldFilter)
			return WorldFilters.IsNameFiltered(FilterType, InName);

		return ViewportFilters.IsNameFiltered(FilterType, InName);
	}

	UFUNCTION(BlueprintOverride)
	bool IsFiltered(const UObject Object) const
	{
		auto SoundDef = Cast<UHazeSoundDefBase>(Object);
		if (SoundDef != nullptr)
		{
			if (!AudioDebug::IsEnabled(EDebugAudioViewportVisualization::SoundDefs) && !AudioDebug::IsEnabled(EDebugAudioWorldVisualization::SoundDefs))
				return true;

			if (AudioDebug::IsEnabled(EDebugAudioViewportVisualization::SoundDefs) && IsFiltered(SoundDef.Name.ToString(), false, EDebugAudioFilter::SoundDefs))
				return true;

			if (AudioDebug::IsEnabled(EDebugAudioWorldVisualization::SoundDefs) && IsFiltered(SoundDef.Name.ToString(), true, EDebugAudioFilter::SoundDefs))
				return true;

			return false;
		}

		return false;
	}

	bool IsVisible(bool bMio = true)
	{
		CreateOverlayWidgets();

		// We always want to draw if we can, so use any drawer IF we can!
		return MiosDrawHelper.IsVisible() || ZoesDrawHelper.IsVisible();
	}

	bool AreDrawersEmpty()
	{
		return !MiosDrawHelper.bHasContent && !ZoesDrawHelper.bHasContent;
	}

	void ResetDrawers()
	{
		MiosDrawHelper.Reset();
		ZoesDrawHelper.Reset();
	}

	void CreateOverlayWidgets()
	{
		// If it hasn't been created yet or the players have been GC:ed/killed
		if (MiosDrawHelper.ImmediateWidget != nullptr &&
			MioDebugData.OverlayWidget != nullptr &&
			MioDebugData.OverlayWidget.Player != nullptr)
			return;

		auto Players = Game::GetPlayers();
		for	(auto Player : Players)
			CreateOverlayWidget(Player);

		if (Players.Num() > 0)
		{
			MiosDrawHelper.ImmediateWidget = Cast<UAudioViewportWidget>(MioDebugData.OverlayWidget).DynamicContent;
			MiosDrawHelper.bIsMio = true;

			ZoesDrawHelper.ImmediateWidget = Cast<UAudioViewportWidget>(ZoeDebugData.OverlayWidget).DynamicContent;
			ZoesDrawHelper.bIsMio = false;		}
	}

	FAudioDebugDrawHelper& GetPreferredDrawer(bool bMio)
	{
		auto& Helper = bMio ? MiosDrawHelper : ZoesDrawHelper;
		auto& OtherHelper = !bMio ? MiosDrawHelper : ZoesDrawHelper;

		if (!Helper.IsVisible())
			return OtherHelper;

		return Helper;
	}

	FHazeImmediateSectionHandle BeginDynamicContentsSection(bool bMio, FHazeImmediateSectionHandle OtherHandle)
	{
		CreateOverlayWidgets();

		auto& PrefHelper = GetPreferredDrawer(bMio);
		if (!PrefHelper.HasBegun())
		{
			return PrefHelper.Begin();
		}

		return OtherHandle;

	}

	void EndDynamicContentsSection(bool bMio)
	{
		CreateOverlayWidgets();

		GetPreferredDrawer(bMio).End();
	}

	void CheckVoxConsoleVars()
	{
		const bool bShouldBeEnabled = VoxCVar::HazeVoxShowViewportTimeline.GetInt() != 0;
		const bool bIsEnabled = VoxViewportOverlayWidget != nullptr;

		if (bShouldBeEnabled != bIsEnabled)
		{
			ToggleVoxViewportOverlayWidget(bShouldBeEnabled);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AudioDebug::CheckConsoleVars();
		CheckVoxConsoleVars();

		int32 WorldFlags = AudioDebug::GetWorldFlags();
		int32 ViewportFlags = AudioDebug::GetViewFlags();
		bAnyDebugActive = WorldFlags != 0 || ViewportFlags != 0;

		if (WorldFlags == 0 && ViewportFlags == 0)
		{
			if (!AreDrawersEmpty())
				ResetDrawers();
			return;
		}

		// We can't draw anything.
		if (!IsVisible())
		{
			if (WorldFlags != 0)
			{
				for (auto Handler : DebugTypeHandlers)
				{
					if (Handler == nullptr)
						continue;

					const auto TypeIndex = int(Handler.Type());
					Handler.bIsWorldDebugEnabled = AudioDebug::IsEnabled(EDebugAudioWorldVisualization(TypeIndex));

					if (Handler.DebugEnabled())
					{
						Handler.Visualize(this);
					}
				}
			}
			return;
		}

		auto BorderColor = FLinearColor::Black;
		BorderColor.A = 0.2;

		auto& MiosHelper = GetPreferredDrawer(true);
		auto& ZoesHelper = GetPreferredDrawer(false);

		// NOTE: These can be used in the same viewport! Based on visibility.
		auto MiosSection = MiosHelper.Begin();
		auto ZoesSection = BeginDynamicContentsSection(false, MiosSection);

		for (auto Handler : DebugTypeHandlers)
		{
			if (Handler == nullptr)
				continue;

			const auto TypeIndex = int(Handler.Type());
			bool bWasWorldEnabled = Handler.bIsWorldDebugEnabled;
			bool bWasViewEnabled = Handler.bIsViewportDebugEnabled;

			Handler.bIsWorldDebugEnabled = AudioDebug::IsEnabled(EDebugAudioWorldVisualization(TypeIndex));
			Handler.bIsViewportDebugEnabled = AudioDebug::IsEnabled(EDebugAudioViewportVisualization(TypeIndex));

			if (bWasWorldEnabled != Handler.bIsWorldDebugEnabled)
			{
				Handler.OnWorldToggled();
			}
			if (bWasViewEnabled != Handler.bIsViewportDebugEnabled)
			{
				Handler.OnViewToggled();
			}

			if (Handler.DebugEnabled())
			{
				Handler.Visualize(this);
			}

			// The drawing is handled elsewhere most likely the audio dev menu.
			if (!Handler.bUseViewportDrawer)
				continue;

			auto& Drawer = Handler.bUseCustomDrawing ? MiosDrawHelper : ZoesDrawHelper;
			auto& PlayerSection = Handler.bUseCustomDrawing ? MiosSection : ZoesSection;

			if (!Handler.bIsViewportDebugEnabled)
				continue;

			// Notify the drawer that it now has content to show, i.e will need to be reset if disabled.
			Drawer.bHasContent = true;

			if (Handler.DrawEnabled())
			{
				// Should we use the default drawing side, or let the handler select itself.
				if (!Handler.bUseCustomDrawing)
				{
					Handler.Draw(this, PlayerSection
										.Section(Handler.GetTitle())
										.Color(BorderColor));
				}
				else
				{
					Handler.DrawCustom(this, MiosSection, ZoesSection);
				}
			}

		}

		EndDynamicContentsSection(true);
		EndDynamicContentsSection(false);
	}

	void ToggleVoxViewportOverlayWidget(bool bShow)
	{
		if (bShow && VoxViewportOverlayWidget == nullptr)
		{
			UHazeUserWidget SpawnedWidget = Widget::AddFullscreenWidget(VoxViewportOverlayWidgetClass, EHazeWidgetLayer::Dev);
			VoxViewportOverlayWidget = Cast<UVoxViewportOverlayWidget>(SpawnedWidget);
		}
		else if (!bShow && VoxViewportOverlayWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(VoxViewportOverlayWidget);
			VoxViewportOverlayWidget = nullptr;
		}
	}
};
