
class UCameraDevMenu : UHazeDevMenuEntryImmediateWidget
{
	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		if (!Drawer.IsVisible())
			return;

		AHazeActor Actor = Cast<AHazeActor>(GetDebugActor());	
		auto Player = Cast<AHazePlayerCharacter>(Actor);

		if(Player == nullptr)
			return;

		UCameraUserComponent User = UCameraUserComponent::Get(Player);
		if(User == nullptr)
			return;
		
		auto DebugUser = UCameraDebugUserComponent::GetOrCreate(Player);

		auto RootPanel = Drawer.BeginVerticalBox().SlotFill()
		.ScrollBox(EOrientation::Orient_Horizontal)
		.VerticalBox();

		TArray<FName> UsedAssets;
	
		// TOP BOX
		{
			auto TopPanel = RootPanel.HorizontalBox();

			// Actor header
			if(Actor != nullptr)
			{
				FString ActorName = Actor.Name.ToString();
				if(Network::IsGameNetworked())
				{
					if(Actor.HasControl())
						ActorName += " (Control)";
					else
						ActorName += " (Remote)";
				}
					
				auto Text = TopPanel.Text(f"{ActorName}").Scale(2.0);
				if(Player != nullptr)
				{
					Text.Color(Player.GetPlayerDebugColor());
				}

				TopPanel.Spacer(10);
			}

			// Settings Buttons
			
			{
				// Focus Target
				{
					auto SettingsPanel = TopPanel.VerticalBox();
					//bool bTrigger = TopPanel.ComboBox();
					TArray<FName> Items;
					Items.Add(NAME_None);
					Items.Add(n"Disabled");
					Items.Add(n"FocusOtherPlayer");
					
					SettingsPanel.Text("Focus Target Override");
					auto ComboBox = SettingsPanel.ComboBox();
					ComboBox.Items(Items);

					DebugUser.FocusDebugType = ComboBox.SelectedItem;
				}

				// Animation Inspection
				{
					TopPanel.Text("   ");
					bool bTrigger = TopPanel.CheckBox()
					.Label("Animation Inspection").Checked(DebugUser.bUsingDebugAnimationInspection);

					if(bTrigger != DebugUser.bUsingDebugAnimationInspection)
					{
						DebugUser.bUsingDebugAnimationInspection = bTrigger;
					}
				}
			}


			// // View Entries
			// {
			// 	bool bTrigger = TopPanel.CheckBox()
			// 	.Label("Always Show Entries").Checked(bAlwaysShowEntries)
			// 	.Tooltip("If checked; will display all the entires for each value with the priority")
			// 	;

			// 	if(bTrigger != bAlwaysShowEntries)
			// 	{
			// 		bAlwaysShowEntries = bTrigger;
			// 	}
			// }
		}
		
		// BOTTOM BOX
		auto BottomPanel = RootPanel.SlotFill().HorizontalBox();
		BottomPanel.SlotPadding(10.0, 10.0, 0.0, 0.0);

		{
			if(User != nullptr)
			{
				auto CameraDebug = User.GetCameraDebugInfo();

				// Header
				if(CameraDebug.AddedCamerasSorted.Num() > 0)
				{
					auto ActiveCameraPanel = BottomPanel.VerticalBox();

					{
						auto CameraHeaderPanel = ActiveCameraPanel.Text("Active Cameras\n");
						CameraHeaderPanel.Color(FLinearColor::Yellow);
						CameraHeaderPanel.Scale(1.5);
						CameraHeaderPanel.Bold();
					}

					// Blend
					{
						FLinearColor DebugColor = FLinearColor::White;

						if(CameraDebug.bHasActiveBlend)
						{
							auto Text = ActiveCameraPanel.SlotPadding(10.0, 0.0).Text(f"Active Blend");
							Text.Scale(1.2);
							Text.Color(DebugColor);
						}
						else
						{
							DebugColor = FLinearColor::Gray;
							auto Text = ActiveCameraPanel.SlotPadding(10.0, 0.0).Text(f"Previous Blend");
							Text.Scale(1.2);
							Text.Color(DebugColor);
						}

						{
							auto Text = ActiveCameraPanel.SlotPadding(20.0, 0.0).Text(f"Blend Time: {CameraDebug.BlendTime}");
							Text.Scale(1.1);
							Text.Color(DebugColor);
						}

						if(CameraDebug.BlendType.IsValid())
						{
							auto Text = ActiveCameraPanel.SlotPadding(20.0, 0.0).Text(f"Blend Type: {CameraDebug.BlendType.Get()}");
							Text.Scale(1.1);
							Text.Color(DebugColor);
						}

						{
							auto Text = ActiveCameraPanel.SlotPadding(20.0, 0.0).Text(f"Blend Alpha: {CameraDebug.Alpha}");
							Text.Scale(1.1);
							Text.Color(DebugColor);
						}

						{
							auto Text = ActiveCameraPanel.SlotPadding(20.0, 0.0).Text(f"Blend Accelerated Alpha: {CameraDebug.AcceleratedAlpha}");
							Text.Scale(1.1);
							Text.Color(DebugColor);
						}

						ActiveCameraPanel.SlotPadding(30.0, 0.0).Text(f"\n");
					}

					for(int i = CameraDebug.AddedCamerasSorted.Num() - 1; i >= 0; --i)
					{
					 	auto CameraIt = CameraDebug.AddedCamerasSorted[i];	

						bool bIsActiveCamera = i == CameraDebug.AddedCamerasSorted.Num() - 1;	
				
						// Camera
						{
							FString CameraName;
							#if EDITOR
							CameraName = CameraIt.Camera.Owner.GetActorLabel();
							CameraName += f"\n({CameraIt.Camera.Owner.GetName()})";
							#else
							CameraName = CameraIt.Camera.Owner.GetName().ToString();
							#endif
							auto Text = ActiveCameraPanel.SlotPadding(10.0, 0.0).Text(f"{CameraName}");
							if(bIsActiveCamera)
							{
							 	Text.Scale(1.3);
							 	Text.Color(FLinearColor::LucBlue);
							}
							else
							{
								Text.Scale(1.1);
								Text.Color(FLinearColor::Gray);
							}
						}

						// Instigator
						for(auto CameraInstigator : CameraIt.Instigators)
						{
							auto Text = ActiveCameraPanel.SlotPadding(30.0, 0.0).Text(f"{CameraInstigator.ToString()}");
							if(bIsActiveCamera)
							{
								Text.Scale(1.1);
								Text.Color(FLinearColor::White);
							}
							else
							{
								Text.Scale(1.1);
								Text.Color(FLinearColor::Gray);
							}
						}

						// Priority
						{
							auto Text = ActiveCameraPanel.SlotPadding(30.0, 0.0).Text(f"{CameraIt.Priority}\n");
							if(bIsActiveCamera)
							{
								Text.Scale(1.0);
								Text.Color(FLinearColor::White);
							}
							else
							{
								Text.Scale(1.1);
								Text.Color(FLinearColor::Gray);
							}
						}
					}
				}
			}
		}
		
		// Current Settings
		UCameraSettings Settings = User.CameraSettings;
		if (Settings != nullptr)
		{
			TArray<FHazeCameraSettingsPropertyDebugInfo> CameraSettings;
			TArray<FHazeCameraSettingsPropertyDebugInfo> SpringArmSettings;
			FHazeCameraSettingsPropertyDebugInfo Clamps;
			TArray<FHazeCameraSettingsPropertyDebugInfo> KeepInViewSettings;
			FHazeCameraSettingsPropertyDebugInfo POI;
			Settings.GetDebugSettingsInfo(CameraSettings, SpringArmSettings, Clamps, KeepInViewSettings, POI);

			auto SettingsPanel = BottomPanel.ScrollBox().VerticalBox();

			// Camera and spring arm settings
			{
				//auto Root = SettingsRoot.ScrollBox().VerticalBox();

				// Header
				{
					auto Text = SettingsPanel.SlotPadding(0, 10).Text("Settings");
					Text.Color(FLinearColor::Yellow);
					Text.Scale(1.5);
					Text.Bold();
				}

				// Body
				{
					for(auto It : CameraSettings)
						LogSettings(SettingsPanel, It, UsedAssets);

					for(auto It : SpringArmSettings)
						LogSettings(SettingsPanel, It, UsedAssets);
				}

				// Log data about aiming mode
				LogAiming(SettingsPanel, User);
			}

			auto AdvancedSettingsPanel = BottomPanel.ScrollBox().VerticalBox();
			{
				// Clamp
				if(Clamps.AffectingValues.Num() > 0)
				{
					auto Text = AdvancedSettingsPanel.SlotPadding(0, 10).Text("Clamps");
					Text.Color(FLinearColor::Yellow);
					Text.Scale(1.5);
					Text.Bold();

					LogSettings(AdvancedSettingsPanel, Clamps, UsedAssets);
				}

				// POI
				if(POI.AffectingValues.Num() > 0)
				{
					auto Text = AdvancedSettingsPanel.SlotPadding(0, 10).Text("Point of Interest");
					Text.Color(FLinearColor::Yellow);
					Text.Scale(1.5);
					Text.Bold();

					LogSettings(AdvancedSettingsPanel, POI, UsedAssets);
				}

				// Keep In view
				if(KeepInViewSettings.Num() > 0)
				{
					auto Text = AdvancedSettingsPanel.SlotPadding(0, 10).Text("KeepInView");
					Text.Color(FLinearColor::Yellow);
					Text.Scale(1.5);
					Text.Bold();

					for(auto It : KeepInViewSettings)
						LogSettings(AdvancedSettingsPanel, It, UsedAssets);
				}

				// Assist
				auto Assist = UCameraAssistComponent::Get(User.Owner);
				if(Assist != nullptr)
				{	
					
					{
						auto Text = AdvancedSettingsPanel.SlotPadding(0, 10).Text("Assists");
						Text.Color(FLinearColor::Yellow);
						Text.Scale(1.5);
						Text.Bold();
					}
	

					{
						auto HeaderRoot = AdvancedSettingsPanel.VerticalBox();
						{		
							if(Assist.IsAssistEnabled())
							{
								// Asset Info
								auto Type = Assist.GetAssistType();
								if(Type != nullptr)
								{
									auto Root = HeaderRoot.HorizontalBox();
									auto Text = Root.SlotPadding(0, 0, 10, 0).Text(f"Asset");
									Text.Color(FLinearColor::LucBlue);
									Text.Scale(1.1);

									FString AssistText = "";
									AssistText += Type.ToString();
									AssistText += "\n";
									AssistText += Assist.GetAssistInstigator().ToPlainString();
									AssistText += "\n";
									AssistText += Assist.GetAssistPriority();
									auto BodyText = Root.SlotPadding(0, 0, 10, 0).Text(AssistText);	
								}

								// Settings Info
								{
									auto Root = HeaderRoot.HorizontalBox();
									auto Text = Root.SlotPadding(0, 0, 10, 0).Text(f"Settings");
									Text.Color(FLinearColor::LucBlue);
									Text.Scale(1.1);

									FString SettingsText = "";
									SettingsText += f"Input Multiplier: {Assist.ActiveAssistSettings.InputMultiplier}";
									SettingsText += "\n";
									SettingsText += f"Contextual Multiplier: {Assist.ActiveAssistSettings.ContextualMultiplier}";
									auto BodyText = Root.SlotPadding(0, 0, 10, 0).Text(SettingsText);	
								}

							}
							else
							{
								auto BodyText = HeaderRoot.SlotPadding(0, 0, 10, 0).Text("Disabled");
								BodyText.Color(FLinearColor::Red);
							}
						}	
					}
				}

				// Modifiers
				{
					auto Text = AdvancedSettingsPanel.SlotPadding(0, 10).Text("Modifiers");
					Text.Color(FLinearColor::Yellow);
					Text.Scale(1.5);
					Text.Bold();

					const FString Rofl = "¯\\_(ツ)_/¯";

					FHazeCameraModifiersDebugData ModifiersDebugData;
					User.Modifier.GetDebugData(ModifiersDebugData);

					// Shakes
					{
						auto ShakesText = AdvancedSettingsPanel.SlotPadding(0, 10).Text("Shakes");
						ShakesText.Color(FLinearColor::LucBlue);
						ShakesText.Scale(1.2);

						if (ModifiersDebugData.Shakes.IsEmpty())
						{
							auto HeaderRoot = AdvancedSettingsPanel.VerticalBox().HorizontalBox();
								HeaderRoot.SlotPadding(0, 0, 10, 0).Text(Rofl);
						}
						else
						{
							for (auto Shake : ModifiersDebugData.Shakes)
							{
								auto HeaderRoot = AdvancedSettingsPanel.VerticalBox().HorizontalBox();
									HeaderRoot.SlotPadding(0, 0, 10, 0).Text(Shake);
							}
						}
					}

					// Impulses
					{
						auto ShakesText = AdvancedSettingsPanel.SlotPadding(0, 10).Text("Impulses");
						ShakesText.Color(FLinearColor::LucBlue);
						ShakesText.Scale(1.2);

						if (ModifiersDebugData.Impulses.IsEmpty())
						{
							auto HeaderRoot = AdvancedSettingsPanel.VerticalBox().HorizontalBox();
								HeaderRoot.SlotPadding(0, 0, 10, 0).Text(Rofl);
						}
						else
						{
							for (auto Impulse : ModifiersDebugData.Impulses)
							{
								auto HeaderRoot = AdvancedSettingsPanel.VerticalBox().HorizontalBox();
									HeaderRoot.SlotPadding(0, 0, 10, 0).Text(Impulse);
							}
						}
					}
				}
			}
		}	

		if(UsedAssets.Num() > 0)
		{
			auto AdvancedSettingsPanel = BottomPanel.ScrollBox().VerticalBox();
			{
				auto AssetPanel = AdvancedSettingsPanel.Text("Used Assets");
				AssetPanel.Color(FLinearColor::Yellow);
				AssetPanel.Scale(1.5);
				AssetPanel.Bold();
			}

			for(auto Asset : UsedAssets)
			{
				FString AssetName = Asset.ToString();
				if(AdvancedSettingsPanel.Button(" " + AssetName + " "))
				{
					Editor::OpenEditorForAsset(AssetName);
				}	
			}
		}
	}

	void LogSettings(FHazeImmediateVerticalBoxHandle& RootOwner, FHazeCameraSettingsPropertyDebugInfo Setting, TArray<FName>& AssetRefs)
	{
		auto Root = RootOwner.VerticalBox();
		const bool bHasValues = Setting.AffectingValues.IsValidIndex(Setting.HighestAffectingValue) || Setting.Additives.Num() > 0;
	
		// auto HeaderRoot = Root.VerticalBox();
		// auto ValueRoot = Root.VerticalBox();
	
		// Property header
		{
			{
				auto HeaderRoot = Root.HorizontalBox();
				{
					auto Text = HeaderRoot.SlotPadding(0, 0, 10, 0).Text(f"{Setting.PropertyName}");
					Text.Color(FLinearColor::LucBlue);
					Text.Scale(1.1);	
				}

				{
					auto Text = HeaderRoot.SlotPadding(0, 0).Text(f"{Setting.CurrentValue}");
					Text.Color(FLinearColor::White);
					Text.Scale(1.1);	
				}
			}
		}


		for(int i = Setting.AffectingValues.Num() - 1; i >= 0; --i)
		{
			// We only show more info of the values if we are blending in
			const auto& InstigatedSetting = Setting.AffectingValues[i];
			FLinearColor ValueColor = FLinearColor(0.31, 0.31, 0.31);

			bool ShowBlendInfo = true;
			bool ShowWeightInfo = true;
			if(!InstigatedSetting.bBlendingOut)
			{
				if(InstigatedSetting.Alpha > 1 - KINDA_SMALL_NUMBER)
					ShowBlendInfo = false;
				else
					ValueColor = FLinearColor(0.05, 0.30, 0.05);
					

				if(InstigatedSetting.Fraction > 1 - KINDA_SMALL_NUMBER)
					ShowWeightInfo = false;
			}
			else
			{
				ShowWeightInfo = false;

				ValueColor = FLinearColor(0.30, 0.05, 0.05);
				if(InstigatedSetting.Alpha < KINDA_SMALL_NUMBER)
					ShowBlendInfo = false;		
			}

			// Show Value Type
			{
				FString ValueType = "";
				if(InstigatedSetting.AssetRef != nullptr)
				{
					ValueType = InstigatedSetting.AssetRef.Name.ToString();
					AssetRefs.AddUnique(InstigatedSetting.AssetRef.Name);
				}
				else
				{
					ValueType = "<custom>";
				}

				if(InstigatedSetting.PropertyValue.Len() < 10)
				{
					auto Text = Root.Text(f" * {ValueType} | {InstigatedSetting.PropertyValue}");
					Text.Color(ValueColor);
				}
				else
				{
					{
						auto Text = Root.Text(f" * {ValueType}");
						Text.Color(ValueColor);
					}

					// To long values will be placed on the next row
					{
						auto Text = Root.SlotPadding(14, 0).Text(f"{InstigatedSetting.PropertyValue}");
						Text.Color(ValueColor);
					}
				}
			}

			// Instigator
			{
				FString InstigatorText = InstigatedSetting.Instigator;
				InstigatorText.RemoveFromStart("{");
				InstigatorText.RemoveFromStart("Instigator");
				InstigatorText.RemoveFromStart(":");
				InstigatorText.RemoveFromEnd("}");

				auto Text = Root.Text(f"    {InstigatedSetting.Priority} | {InstigatorText}");
				Text.Color(ValueColor);
			}

	
			// body
			{
				if(ShowBlendInfo)
				{
					FString BlendingOut = InstigatedSetting.bBlendingOut ? " | BlendingOut" : "";
					auto TextBlend = Root.Text(
						f"    Alpha: {InstigatedSetting.Alpha :.2} | BlendTime: {InstigatedSetting.BlendTime :.2}{BlendingOut}");
					TextBlend.Color(ValueColor);
				}

				if(ShowWeightInfo)
				{
					auto TextBody = Root.Text(
						f"    Value: {InstigatedSetting.TargetValue} | Weight: {InstigatedSetting.Fraction :.2}");
					TextBody.Color(ValueColor);
				}
			}
		}

		// Additives
		for(int i = Setting.Additives.Num() - 1; i >= 0; --i)
		{
			// We only show more info of the values if we are blending in
			const auto& InstigatedSetting = Setting.Additives[i];
			FLinearColor ValueColor = FLinearColor(0.31, 0.31, 0.31);

			bool ShowBlendInfo = true;
			bool ShowWeightInfo = true;
			if(!InstigatedSetting.bBlendingOut)
			{
				if(InstigatedSetting.Alpha > 1 - KINDA_SMALL_NUMBER)
					ShowBlendInfo = false;
				else
					ValueColor = FLinearColor(0.05, 0.30, 0.05);
					

				if(InstigatedSetting.Fraction > 1 - KINDA_SMALL_NUMBER)
					ShowWeightInfo = false;
			}
			else
			{
				ShowWeightInfo = false;

				ValueColor = FLinearColor(0.30, 0.05, 0.05);
				if(InstigatedSetting.Alpha < KINDA_SMALL_NUMBER)
					ShowBlendInfo = false;		
			}

			// Show Value Type
			{
				FString ValueType = "";
				if(InstigatedSetting.AssetRef != nullptr)
				{
					ValueType = InstigatedSetting.AssetRef.Name.ToString();
					AssetRefs.AddUnique(InstigatedSetting.AssetRef.Name);
				}
				else
				{
					ValueType = "<custom>";
				}

				if(InstigatedSetting.PropertyValue.Len() < 10)
				{
					auto Text = Root.Text(f" * {ValueType} | {InstigatedSetting.PropertyValue}");
					Text.Color(ValueColor);
				}
				else
				{
					{
						auto Text = Root.Text(f" * {ValueType}");
						Text.Color(ValueColor);
					}

					// To long values will be placed on the next row
					{
						auto Text = Root.SlotPadding(14, 0).Text(f"{InstigatedSetting.PropertyValue}");
						Text.Color(ValueColor);
					}
				}
			}
			
			// Additive
			{
				auto Text = Root.Text(f"    <Additive>");
				Text.Color(ValueColor);
			}

			// Instigator
			{
				FString InstigatorText = InstigatedSetting.Instigator;
				InstigatorText.RemoveFromStart("{");
				InstigatorText.RemoveFromStart("Instigator");
				InstigatorText.RemoveFromStart(":");
				InstigatorText.RemoveFromEnd("}");

				auto Text = Root.Text(f"    {InstigatedSetting.Priority} | {InstigatorText}");
				Text.Color(ValueColor);
			}

	
			// body
			{
				if(ShowBlendInfo)
				{
					FString BlendingOut = InstigatedSetting.bBlendingOut ? " | BlendingOut" : "";
					auto TextBlend = Root.Text(
						f"    Alpha: {InstigatedSetting.Alpha :.2} | BlendTime: {InstigatedSetting.BlendTime :.2}{BlendingOut}");
					TextBlend.Color(ValueColor);
				}

				if(ShowWeightInfo)
				{
					auto TextBody = Root.Text(
						f"    Value: {InstigatedSetting.PropertyValue} | Weight: {InstigatedSetting.Fraction :.2}");
					TextBody.Color(ValueColor);
				}
			}
		}
	}

	FString GetCurveInfo(UCurveFloat Curve) const
	{
		if(Curve != nullptr)
		{
			FString Info = f" * {Curve.GetName()} \n";

			float32 TimeMin = 0;
			float32 TimeMax = 0;
			Curve.GetTimeRange(TimeMin, TimeMax);
			Info += f"   Time: {TimeMin} -> {TimeMax} \n";

			float32 ValueMin = 0;
			float32 ValueMax = 0;
			Curve.GetValueRange(ValueMax, ValueMax);
			Info += f"   Value: {ValueMin} -> {ValueMax} \n";
		
			return Info;
		}
		else
		{

			return " * nullptr";
		}
	}

	FString GetCurveInfo(FRuntimeFloatCurve Curve) const
	{
		FString Info = f" *  { Curve.ToString() } \n";

		float32 TimeMin = 0;
		float32 TimeMax = 0;
		Curve.GetTimeRange(TimeMin, TimeMax);
		Info += f"   Time: {TimeMin} -> {TimeMax} \n";

		float32 ValueMin = 0;
		float32 ValueMax = 0;
		Curve.GetValueRange(ValueMax, ValueMax);
		Info += f"   Value: {ValueMin} -> {ValueMax} \n";
	
		return Info;
	}

	void LogAiming(FHazeImmediateVerticalBoxHandle& Root, UCameraUserComponent UserComp)
	{
		TArray<FInstigator> Instigators = UserComp.GetAimingInstigators();

		auto HeaderRoot = Root.HorizontalBox();
		{
			auto Text = HeaderRoot
				.SlotPadding(0, 0, 10, 0)
				.Text("Aiming Sensitivity");
			Text.Color(FLinearColor::LucBlue);
			Text.Scale(1.1);	
		}

		{
			auto Text = HeaderRoot
				.SlotPadding(0, 0)
				.Text(
					Instigators.Num() == 0 ? "false" : "true"
				);

			if (Instigators.Num() == 0)
				Text.Color(FLinearColor::Red);
			else
				Text.Color(FLinearColor::Green);

			Text.Scale(1.1);	
		}

		// List aiming instigators
		for (FInstigator Instigator : Instigators)
		{
			auto Text = Root.Text(f"    Aim Instigator: {Instigator.ToPlainString()}");
			Text.Color(FLinearColor(0.25, 0.25, 0.25));
		}
	}
}