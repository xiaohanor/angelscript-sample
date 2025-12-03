
class UHazeAudioDevMenuTestSoundsAsset : UDataAsset
{
	UPROPERTY(EditAnywhere)
	UHazeAudioEvent Explosion;

	UPROPERTY(EditAnywhere)
	UHazeAudioEvent Weapon;

	UPROPERTY(EditAnywhere)
	UHazeAudioEvent Gadget;

	UPROPERTY(EditAnywhere)
	UHazeAudioEvent Ability;

	UPROPERTY(EditAnywhere)
	UHazeAudioEvent VO;
}

namespace AudioDebugManager
{
	UAudioDebugManager Get()
	{
		FScopeDebugPrimaryWorld ScopeWorld;
		return Cast<UAudioDebugManager>(UHazeAudioDebugManager::Get());
	}
};

class UHazeAudioDevMenu : UHazeDevMenuEntryWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget Content;

	UAudioDebugManager DebugManager;

	const FConsoleVariable CVar_AudioDebugWorldVisualizationFlags("HazeAudio.DebugWorldVisualizationFlags", 0);
	const FConsoleVariable CVar_AudioDebugViewportVisualizationFlags("HazeAudio.DebugViewportVisualizationFlags", 0);
	const FConsoleVariable CVar_DisableAudioOutputs("DisableAudioOutputs", 0, "Mutes audio posted by either Remote|Control|None side");

	const FConsoleVariable CVar_ComponentController("HazeAudio.Feature_ComponentController", 1);
	const FConsoleVariable CVar_Delay("HazeAudio.Feature_Delay", 1);

	const FConsoleVariable CVar_SoundDefLimiting("HazeAudio.Feature_SoundDefLimiting", 1);
	const FConsoleVariable CVar_SoundDefController("HazeAudio.Feature_SoundDefController", 1);
	const FConsoleVariable CVar_SoundDefForceDisabling("HazeAudio.Feature_SoundDefForceDisabling", 1);
	const FConsoleVariable CVar_MusicFadeOutOnEndplay("HazeAudio.Feature_MusicFadeOutOnEndplay", 0);

 	TArray<FString> WorldButtons;
 	default WorldButtons.SetNum(EDebugAudioWorldVisualization::Num);

 	TArray<FString> ViewportButtons;
 	default ViewportButtons.SetNum(EDebugAudioViewportVisualization::Num);

	TArray<FName> NetworkOutputSelections;
 	default NetworkOutputSelections.SetNum(EDebugAudioOutputBlock::Num);

	int SelectedBanksState = int(EBankLoadState::Uninitialized);
	TArray<FName> BankStateSelections;
 	default BankStateSelections.SetNum(EBankLoadState::EBankLoadState_MAX);

	int SelectedCutsceneTag = int(EHazeLevelSequenceTag::Undefined);
	TArray<FName> CutsceneTagSelections;
 	default CutsceneTagSelections.SetNum(EHazeLevelSequenceTag::EHazeLevelSequenceTag_MAX);

	const FHazeAudioID Rtpc_Debug_Toggle_Music = FHazeAudioID("Rtpc_Debug_Toggle_Music");
	const FHazeAudioID Rtpc_Debug_Toggle_SFX = FHazeAudioID("Rtpc_Debug_Toggle_SFX");
	const FHazeAudioID Rtpc_Debug_Toggle_VO = FHazeAudioID("Rtpc_Debug_Toggle_VO");
	const FHazeAudioID Rtpc_Debug_Toggle_VO_TTS = FHazeAudioID("Rtpc_Debug_Toggle_VO_TTS");

	bool bUseSpatialPanning = true;
	bool bUseSpatialPanningGain = true;
	bool bUseGameDefSendFix = true;
	bool bUseControllerOutput = false;

	int SelectedPlayer = 0;
	TArray<FName> PlayerSelections;
 	default PlayerSelections.SetNum(EHazePlayer::MAX);

	UHazeAudioDevMenuTestSoundsAsset TestSoundsAsset;

	TArray<UAudioDebugTypeHandler> DebugTypeHandlers;
	default DebugTypeHandlers.SetNum(EHazeAudioDebugType::NumOfTypes);

	UHazeAudioDevMenuConfig MenuDebugConfig;
	UHazeAudioDebugConfig DebugConfig;

	const FLinearColor GreyColor = FLinearColor(0.05, 0.05, 0.05);
	const FLinearColor GreenColor = FLinearColor(0.05, 0.55, 0.00);
	const FLinearColor GameColor = FLinearColor(0.43, 0.35, 0.00);

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		MenuDebugConfig = AudioDebug::GetMenuConfig();
		DebugConfig = AudioDebug::GetConfig();

		Console::SetConsoleVariableInt("HazeAudio.DebugWorldVisualizationFlags", DebugConfig.WorldFlags, "", true);
		Console::SetConsoleVariableInt("HazeAudio.DebugViewportVisualizationFlags", DebugConfig.ViewFlags, "", true);

		for (int i=0; i < int(EDebugAudioWorldVisualization::Num); ++i)
		{
			WorldButtons[i] = f"{EDebugAudioWorldVisualization(i) :n}";
		}

		for (int i=0; i < int(EDebugAudioViewportVisualization::Num); ++i)
		{
			ViewportButtons[i] = f"{EDebugAudioViewportVisualization(i) :n}";
		}

		for (int i=0; i < int(EBankLoadState::EBankLoadState_MAX); ++i)
		{
			BankStateSelections[i] = FName(f"{EBankLoadState(i) :n}");
		}

		for (int i=0; i < int(EHazeLevelSequenceTag::EHazeLevelSequenceTag_MAX); ++i)
		{
			CutsceneTagSelections[i] = FName(f"{EHazeLevelSequenceTag(i) :n}");
		}

		for (int i=0; i < int(EDebugAudioOutputBlock::Num); ++i)
		{
			NetworkOutputSelections[i] = FName(f"{EDebugAudioOutputBlock(i) :n}");
		}

		for (int i=0; i < int(EHazePlayer::MAX); ++i)
		{
			PlayerSelections[i] = FName(f"{EHazePlayer(i) :n}");
		}

		bool bSetDefaultValues = MenuDebugConfig.InViewportOrMenuFlags == -1;
		if (bSetDefaultValues)
		{
			MenuDebugConfig.InViewportOrMenuFlags = 0;
		}

		const auto Classes = UClass::GetAllSubclassesOf(UAudioDebugTypeHandler);
		for (UClass HandlerClass: Classes)
		{
			auto DebugHandler = AudioDebug::GetHandlerOfType(HandlerClass);
			if (DebugHandler == nullptr)
				continue;

			if (DebugHandler.Type() >= EHazeAudioDebugType::NumOfTypes)
				continue;

			DebugTypeHandlers[DebugHandler.Type()] = DebugHandler;

			if (bSetDefaultValues && DebugHandler.bUseViewportDrawer)
				MenuDebugConfig.InViewportOrMenuFlags |= 1 << uint(DebugHandler.Type());
		}

		if (bSetDefaultValues)
		{
			MenuDebugConfig.Save();
		}

		// Saved setting.
		SetGlobalRTPC(Rtpc_Debug_Toggle_VO_TTS, MenuDebugConfig.bEnableTTS ? 1: 0);
	}

	void ToggleWorldDebugging(EDebugAudioWorldVisualization VisualizationType)
	{
		DebugConfig.WorldFlags = AudioDebug::ToggleDebugging(VisualizationType);
		DebugConfig.Save();
	}

	void ToggleViewportDebugging(EDebugAudioViewportVisualization VisualizationType)
	{
		DebugConfig.ViewFlags = AudioDebug::ToggleDebugging(VisualizationType);
		DebugConfig.Save();
	}

	void ToggleInGameOrMenu(int InViewportOrMenuFlag)
	{
		MenuDebugConfig.InViewportOrMenuFlags = AudioDebug::ToggleBit(MenuDebugConfig.InViewportOrMenuFlags, InViewportOrMenuFlag, false);
		MenuDebugConfig.Save();

		if (DebugTypeHandlers.IsValidIndex(InViewportOrMenuFlag))
		{
			if (DebugTypeHandlers[InViewportOrMenuFlag] != nullptr)
				DebugTypeHandlers[InViewportOrMenuFlag].bUseViewportDrawer = (MenuDebugConfig.InViewportOrMenuFlags & (1 << uint(InViewportOrMenuFlag))) != 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnSetDevMenuIsActive(bool bIsActive)
	{
		if (DebugManager != nullptr)
			DebugManager.bDevMenuFocus = bIsActive;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (!Content.Drawer.IsVisible())
			return;

		if (!Editor::HasPrimaryGameWorld())
		{
			AudioDebug::CheckConsoleVars();
		}
		else if (DebugManager == nullptr)
		{
			DebugManager = AudioDebugManager::Get();
			if (DebugManager != nullptr)
				DebugManager.DevMenu = this;
		}

 		auto Section = Content.Drawer.Begin();

		// COMMON SETTINGS
		auto SettingsBox = Section.VerticalBox();
		{
			SettingsBox.Text("SETTINGS")
				.Color(FLinearColor::Yellow)
				.Bold()
				.Scale(2.0);

			auto SettingsSection = SettingsBox.Section();
			auto HorizontalBox = SettingsSection.HorizontalBox();

			auto VolumeBox = HorizontalBox.VerticalBox();
			{
				VolumeBox.Text("Enable/Disable Volume");
				
				bool _NoSavedSetting = false;
				DrawMuteCheckbox(VolumeBox, Rtpc_Debug_Toggle_Music, "Music", _NoSavedSetting);
				DrawMuteCheckbox(VolumeBox, Rtpc_Debug_Toggle_SFX, "SFX", _NoSavedSetting);
				DrawMuteCheckbox(VolumeBox, Rtpc_Debug_Toggle_VO, "VO", _NoSavedSetting);
				DrawMuteCheckbox(VolumeBox, Rtpc_Debug_Toggle_VO_TTS, "TTS", MenuDebugConfig.bEnableTTS);

				// Lower both VO and SFX, but a set amount. Will disable usage of above checkboxes
				DrawLowerVolumeCheckbox(VolumeBox, "Lower SFX and VO");
			}

			// NETWORK
			auto NetworkBox = HorizontalBox.VerticalBox();
			{
				NetworkBox.Text("Mute (ONLY IN NETWORK)");

				int CurrentValue = CVar_DisableAudioOutputs.GetInt();

				auto NetworkModeComboBox = NetworkBox
					.ComboBox()
					.Tooltip("Mutes audio posted by either Remote|Control|None side")
					.Items(NetworkOutputSelections)
					.Value(NetworkOutputSelections[CurrentValue]);

				if (NetworkModeComboBox.GetSelectedIndex() != CurrentValue)
				{
					auto SelectedMode = EDebugAudioOutputBlock(NetworkModeComboBox.GetSelectedIndex());
					Console::SetConsoleVariableInt("DisableAudioOutputs", int(SelectedMode), "Mutes audio posted by either Remote|Control|None side", false);
				}
			}


			auto PostEventSection = HorizontalBox.VerticalBox();
			{
#if EDITOR
				if (TestSoundsAsset == nullptr)
					TestSoundsAsset = Cast<UHazeAudioDevMenuTestSoundsAsset>(
						 LoadObject(nullptr, "/Game/Audio/DataAssets/TestAssets/DevMenuTestSounds.DevMenuTestSounds")
					);
#endif

				auto VerticalBox = PostEventSection.VerticalBox();
				if (TestSoundsAsset != nullptr)
				{
					VerticalBox.Text("POST EVENT")
						.Color(FLinearColor::Purple)
						.Bold();

					auto SelectedPlayerBox = VerticalBox
						.ComboBox()
						.Tooltip("Select which player to use as a location")
						.Items(PlayerSelections)
						.Value(PlayerSelections[SelectedPlayer]);

					SelectedPlayer = SelectedPlayerBox.GetSelectedIndex();

					DrawTestSoundButton(VerticalBox, "Explosion", TestSoundsAsset.Explosion);
					DrawTestSoundButton(VerticalBox, "Weapon", TestSoundsAsset.Weapon);
					DrawTestSoundButton(VerticalBox, "Gadget", TestSoundsAsset.Gadget);
					DrawTestSoundButton(VerticalBox, "Ability", TestSoundsAsset.Ability);
					DrawTestSoundButton(VerticalBox, "VO", TestSoundsAsset.VO);
				}
			}

			auto ExtraButtonSection = HorizontalBox.VerticalBox();
			{
				auto VerticalBox = ExtraButtonSection.VerticalBox();
				{
					auto ButtonClicked = VerticalBox
							.Button("Toggle ControllerOutput")
							.BackgroundColor(
								!bUseControllerOutput ? FLinearColor::Red : FLinearColor::Green)
							.Tooltip("Toggle PS5 Controller Output");

					if (ButtonClicked)
					{
						if (!bUseControllerOutput)
						{
							bUseControllerOutput = Audio::AddControllerOutput();
							if (!bUseControllerOutput)
							{
								Error("Failed to find any PS5 controller output to add!");
							}
						}
						else
						{
							Audio::RemoveControllerOutput();
							bUseControllerOutput = false;
						}

					}
				}
			}
		}

		// DEBUG TYPES
		auto ViewportBox = Section.VerticalBox();

		auto DebugTypesBox = ViewportBox
			.VerticalBox()
			.SlotMaxHeight(280)
			.ScrollBox();
		{
			DebugTypesBox.Text("DEBUG TYPE")
				.Color(FLinearColor::Yellow)
				.Bold()
				.Scale(2.0);

			auto HorizontalBox = DebugTypesBox
				.HorizontalBox();
			{
				auto VerticalBox = HorizontalBox
					.VerticalBox();

				int32 ViewFlags = CVar_AudioDebugViewportVisualizationFlags.GetInt();
				int32 WorldFlags = CVar_AudioDebugWorldVisualizationFlags.GetInt();
				int   InViewportOrMenu = MenuDebugConfig.InViewportOrMenuFlags;

				for (uint i = 0; i < uint(ViewportButtons.Num()); ++i)
				{
					// If any flag is active
					auto Color = (ViewFlags & (1 << i) != 0) ||  (WorldFlags & (1 << i) != 0) ?
							FLinearColor::Green : FLinearColor::White;

					VerticalBox
						.SlotPadding(5, 5)
						.Text(f"{ViewportButtons[i]}")
						.Color(Color)
						.Bold();
				}

				auto SecondVerticalBox = HorizontalBox.VerticalBox();

				for (int i = 0; i < ViewportButtons.Num(); ++i)
				{
					auto ButtonsBox = SecondVerticalBox
						.SlotPadding(0,2,0,-1)
						.HorizontalBox();
					{

						// InViewportOrMenuFlags
						FLinearColor Color = InViewportOrMenu & (1 << uint(i)) != 0 ?
							GameColor : GreyColor;
						auto ButtonText = InViewportOrMenu & (1 << uint(i)) != 0 ?
							"Game" : "Menu";

						if (ButtonsBox
							.SlotPadding(2, 1)
							.Button(ButtonText)
							.Tooltip("Display the text either in Game or Menu View")
							.BackgroundColor(Color))
						{
							ToggleInGameOrMenu(i);
						}

						Color = ViewFlags & (1 << uint(i)) != 0 ?
							GreenColor : GreyColor;

						if (ButtonsBox
							.SlotPadding(2, 1)
							.Button("View")
							.BackgroundColor(Color))
						{
							ToggleViewportDebugging(EDebugAudioViewportVisualization(i));
						}

						Color = WorldFlags & (1 << uint(i)) != 0 ?
							GreenColor : GreyColor;

						if (WorldButtons.IsValidIndex(i) &&
							ButtonsBox
								.SlotPadding(2, 1)
								.Button("World")
								.BackgroundColor(Color))
						{
							ToggleWorldDebugging(EDebugAudioWorldVisualization(i));
						}

					}
				}
			}

			auto DynamicSection = HorizontalBox
				.Section()
				.SlotMaxHeight(380);
			{
				auto ScrollBox = DynamicSection.ScrollBox();
				{
					if (ScrollBox
						.Button("RESET CONFIG")
						.Tooltip("Resets every configured debug settings"))
					{
						MenuDebugConfig.Reset();
						DebugConfig.Reset();
						AudioDebug::ResetConsoleVars();
					}

					DrawObjectFilters(ScrollBox, MenuDebugConfig.ViewFilter, MenuDebugConfig.WorldFilter);

					DrawDebugHandlersMenu(ScrollBox);
				}
			}
		}

		// INGAME
		{
			auto InGameSection = ViewportBox
				.Section()
				.SlotMaxHeight(360);
			{
				auto InGameScrollBox = InGameSection.ScrollBox();
				{
					DrawDebugHandlersData(InGameScrollBox);
				}
			}
		}

			// Scroll the viewport
			// {
			// 	auto NewValue = ViewportBox
			// 		.FloatInput()
			// 		.Label("Viewport scroll")
			// 		.Value(DebugManager.ViewportScrollOffset)
			// 		.MinMax(0, 1);

			// 	DebugManager.ViewportScrollOffset = NewValue;
			// }

		// FEATURE SETTINGS
		auto FeatureSettingsBox = Section.VerticalBox();
		{
			FeatureSettingsBox.Text("FEATURES")
				.Color(FLinearColor::Yellow)
				.Bold()
				.Scale(2.0);

			auto SettingsSection = FeatureSettingsBox.Section();
			auto HorizontalBox = SettingsSection.HorizontalBox();

			auto WwiseFeaturesBox = HorizontalBox.VerticalBox();
			{
				WwiseFeaturesBox.Text("Enable/Disable Features");
				// SPATIAL PANNING
				{
					FString CheckboxName = "Spatial Panning";

					bool CheckBoxEnabled = WwiseFeaturesBox
						.CheckBox()
						.Checked(bUseSpatialPanning)
						.Label(CheckboxName)
						.Tooltip(f"If {CheckboxName} is enabled or not");

					if (CheckBoxEnabled != bUseSpatialPanning)
					{
						bUseSpatialPanning = CheckBoxEnabled;
						AudioUtility::SetHazeFeatureFlag(1 << 1, bUseSpatialPanning);
					}
				}
				// SPATIAL PANNING GAIN
				{
					FString CheckboxName = "Spatial Panning Gain";

					bool CheckBoxEnabled = WwiseFeaturesBox
						.CheckBox()
						.Checked(bUseSpatialPanningGain)
						.Label(CheckboxName)
						.Tooltip(f"If {CheckboxName} is enabled or not");

					if (CheckBoxEnabled != bUseSpatialPanningGain)
					{
						bUseSpatialPanningGain = CheckBoxEnabled;
						AudioUtility::SetHazeFeatureFlag(1 << 6, bUseSpatialPanningGain);
					}
				}
				// NEW AUX SEND FIX
				{
					FString CheckboxName = "GameDefSend is audible if HDR voice is audible";

					bool CheckBoxEnabled = WwiseFeaturesBox
						.CheckBox()
						.Checked(bUseGameDefSendFix)
						.Label(CheckboxName)
						.Tooltip(f"If {CheckboxName} is enabled or not");

					if (CheckBoxEnabled != bUseGameDefSendFix)
					{
						bUseGameDefSendFix = CheckBoxEnabled;
						AudioUtility::SetHazeFeatureFlag(1 << 0, bUseGameDefSendFix);
					}
				}

				// AudioComponent - Activation
				{
					DrawFeatureCheckbox(CVar_ComponentController, WwiseFeaturesBox, "HazeAudio.Feature_ComponentController", "AudioComponent - ActivationController");
					DrawFeatureCheckbox(CVar_Delay, WwiseFeaturesBox, "HazeAudio.Feature_Delay", "Reflection - Delay");
					
					DrawFeatureCheckbox(CVar_SoundDefLimiting, WwiseFeaturesBox, "HazeAudio.Feature_SoundDefLimiting", "SoundDef - Instance Limiting");
					DrawFeatureCheckbox(CVar_SoundDefController, WwiseFeaturesBox, "HazeAudio.Feature_SoundDefController", "SoundDef - TickController");
					DrawFeatureCheckbox(CVar_SoundDefForceDisabling, WwiseFeaturesBox, "HazeAudio.Feature_SoundDefForceDisabling", "SoundDef - Disable components on deactivate");
					
					DrawFeatureCheckbox(CVar_MusicFadeOutOnEndplay, WwiseFeaturesBox, "HazeAudio.Feature_MusicFadeOutOnEndplay", "Music - Fade out on endplay (editor only!)");
				}
			}
		}

		Content.Drawer.End();
	}

	private void DrawTestSoundButton(
		const FHazeImmediateVerticalBoxHandle& BoxHandle,
		FString ButtonName,
		UHazeAudioEvent Event)
	{
		if (Event == nullptr)
			return;

		if (BoxHandle.Button(ButtonName) && DebugManager != nullptr)
		{
			FAngelscriptGameThreadScopeWorldContext WorldScope(DebugManager);
			auto Player = Game::GetPlayer(EHazePlayer(SelectedPlayer));
			if (Player == nullptr)
				return;

			FHazeAudioFireForgetEventParams Params;
			Params.Transform.SetLocation(Player.GetActorLocation());

			AudioComponent::PostFireForget(Event, Params);
		}
	}

	void DrawObjectFilters(const FHazeImmediateScrollBoxHandle& BoxHandle,
		FAudioDebugFilter& ViewFilter,
		FAudioDebugFilter& WorldFilter)
	{
		BoxHandle.Text("Filters (View/World);").Bold();

		for (int i = 0; i < int(EDebugAudioFilter::Num); ++i)
		{
			int FlagToCheck = i;
			if (i == int(EDebugAudioFilter::RTPCs) || i == int(EDebugAudioFilter::Events))
			{
				FlagToCheck = int(EDebugAudioFilter::AudioComponents);
			}

			// bool bHasFlag = Flags & (1 << FlagToCheck) != 0;
			if (!AudioDebug::IsEnabled(EDebugAudioViewportVisualization(FlagToCheck))
				&& !AudioDebug::IsEnabled(EDebugAudioWorldVisualization(FlagToCheck)))
				continue;

			auto ObjectFilterBox = BoxHandle
				.HorizontalBox()
				.SlotMaxWidth(150);

			auto ObjectViewFilterHandle = ObjectFilterBox
				.TextInput()
				.Value(ViewFilter.GetFilterText(EDebugAudioFilter(i)));

			auto ObjectWorldFilterHandle = ObjectFilterBox
				.TextInput()
				.Value(WorldFilter.GetFilterText(EDebugAudioFilter(i)));

			ObjectFilterBox.Text(f" - {ViewFilter.TypeNames[i]}")
				.Bold()
				.Color(FLinearColor::Teal)
				.Scale(1.1);

			// By feature request, split search by "or" (implicit by space), "and" and "not".
			if (ViewFilter.SetFilter(i, ObjectViewFilterHandle))
			{
				MenuDebugConfig.Save();
			}

			if (WorldFilter.SetFilter(i, ObjectWorldFilterHandle))
			{
				MenuDebugConfig.Save();
			}
		}
	}

	void DrawMuteCheckbox(const FHazeImmediateVerticalBoxHandle& VolumeBox, const FHazeAudioID& ID, const FString CheckboxName, bool& bEnabled)
	{
		float32 Value = 0;
		// GetGlobalRtpc doesn't require an world, we get the value from the sound engine.
		auto bWasEnabled = GetCachedGlobalRTPC(ID, Value) == false || Value > 0;

		bool CheckBoxEnabled = VolumeBox
			.CheckBox()
			.Checked(bWasEnabled)
			.Label(CheckboxName)
			.Tooltip(f"If {CheckboxName} is enabled or not, can't be modified if Lower SFX and VO is enabled");

		if (Value > 0 && Value < 1)
			return;

		// Values are cached in global emitter.
		if (CheckBoxEnabled != bWasEnabled)
		{
			SetGlobalRTPC(ID, CheckBoxEnabled ? 1 : 0);
			bEnabled = CheckBoxEnabled;
			MenuDebugConfig.Save();
		}
	}

	void DrawLowerVolumeCheckbox(const FHazeImmediateVerticalBoxHandle& VolumeBox, const FString CheckboxName)
	{
		float32 SFXValue = 0;
		float32 VOValue = 0;

		// GetGlobalRtpc doesn't require an world, we get the value from the sound engine.
		auto bSFXLowered = GetCachedGlobalRTPC(Rtpc_Debug_Toggle_SFX, SFXValue) == true && SFXValue > 0 && SFXValue < 1;
		auto bVOLowered = GetCachedGlobalRTPC(Rtpc_Debug_Toggle_VO, VOValue) == true && VOValue > 0 && VOValue < 1;

		bool CheckBoxEnabled = VolumeBox
			.CheckBox()
			.Checked(bSFXLowered && bVOLowered)
			.Label(CheckboxName)
			.Tooltip(f"If {CheckboxName} is enabled it will lower SFX and VO");

		// Values are cached in global emitter.
		if (CheckBoxEnabled != (bSFXLowered && bVOLowered))
		{
			SetGlobalRTPC(Rtpc_Debug_Toggle_SFX, CheckBoxEnabled ? .5 : 1);
			SetGlobalRTPC(Rtpc_Debug_Toggle_VO, CheckBoxEnabled ? .5 : 1);
		}
	}

	void SetGlobalRTPC(const FHazeAudioID& ID, const float& Value)
	{
	#if EDITOR
		// While not playing use a editor world to set the rtpcs
		if (!Editor::HasPrimaryGameWorld())
		{
			// Get an world, for posting rtpcs for example.
			FScopeDebugEditorWorld ScopeEditorWorld;
			AudioComponent::SetGlobalRTPC(ID, Value);
		}
		else
	#endif
		{
			FScopeDebugPrimaryWorld ScopeWorld;
			AudioComponent::SetGlobalRTPC(ID, Value);
		}
	}

	bool GetCachedGlobalRTPC(const FHazeAudioID& ID, float32& Value)
	{
	#if EDITOR
		// While not playing use a editor world to set the rtpcs
		if (!Editor::HasPrimaryGameWorld())
		{
			// Get an world, for posting rtpcs for example.
			FScopeDebugEditorWorld ScopeEditorWorld;
			return AudioComponent::GetCachedGlobalRTPC(ID, Value);
		}
		else
	#endif
		{
			FScopeDebugPrimaryWorld ScopeWorld;
			return AudioComponent::GetCachedGlobalRTPC(ID, Value);
		}
	}

	void DrawFeatureCheckbox(const FConsoleVariable& ConsoleVariable, const FHazeImmediateVerticalBoxHandle& FeatureBox, const FString& CVAR_Name, const FString CheckboxName)
	{
		float32 Value = 0;
		auto bEnabled = ConsoleVariable.GetInt() == 1;

		bool CheckBoxEnabled = FeatureBox
			.CheckBox()
			.Checked(bEnabled)
			.Label(CheckboxName)
			.Tooltip(f"If {CheckboxName} is enabled or not");

		if (CheckBoxEnabled != bEnabled)
			Console::SetConsoleVariableInt(CVAR_Name, CheckBoxEnabled ? 1 : 0, "", true);
	}

	void DrawDebugHandlersMenu(const FHazeImmediateScrollBoxHandle& Handle)
	{
		int32 ViewFlags = CVar_AudioDebugViewportVisualizationFlags.GetInt();
		int32 WorldFlags = CVar_AudioDebugWorldVisualizationFlags.GetInt();

		for (auto Handler : DebugTypeHandlers)
		{
			if (Handler == nullptr)
				continue;

			uint TypeInt = uint(Handler.Type());
			bool bEnabled = (ViewFlags & (1 << TypeInt) != 0) || (WorldFlags & (1 << TypeInt) != 0);

			if (!bEnabled)
				continue;

			Handler.Menu(this, DebugManager, Handle);
		}
	}

	void DrawDebugHandlersData(const FHazeImmediateScrollBoxHandle& Handle)
	{
		if (DebugManager == nullptr)
			return;

		int32 ViewFlags = CVar_AudioDebugViewportVisualizationFlags.GetInt();
		int32 WorldFlags = CVar_AudioDebugWorldVisualizationFlags.GetInt();

		FAngelscriptGameThreadScopeWorldContext DebugScope(DebugManager);

		for (auto Handler : DebugTypeHandlers)
		{
			if (Handler == nullptr)
				continue;

			if (Handler.bUseViewportDrawer && !Handler.bUseCustomDrawing)
				continue;

			uint TypeInt = uint(Handler.Type());
			bool bEnabled = (ViewFlags & (1 << TypeInt) != 0) ||  (WorldFlags & (1 << TypeInt) != 0);

			if (!bEnabled)
				continue;
			
			if (!Handler.bUseCustomDrawing)
				Handler.Draw(DebugManager, Handle.Section(Handler.GetTitle()));
			else
			{
				auto Section = Handle.Section(Handler.GetTitle());
				Handler.DrawCustom(DebugManager, Section, Section);
			}
		}
	}
};
