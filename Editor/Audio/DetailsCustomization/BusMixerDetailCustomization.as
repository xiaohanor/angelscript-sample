struct FHazeAudioBusMixerDetailSetting
{
	TArray<FName> PropertyNames;

	FHazeAudioBusMixerDetailSetting()
	{
		PropertyNames.SetNum(int(EHazeAudioNodeProperty::OutputBusLPF) + 2);
		for (int i = 0, EnumInt = 0; i < int(EHazeAudioNodeProperty::OutputBusLPF) + 1; ++i, ++EnumInt)
		{
			// Deprecated
			if (i == int(EHazeAudioNodeProperty::LFE))
			{
				++EnumInt;
			}
			PropertyNames[i] = FName(f"{EHazeAudioNodeProperty(EnumInt) :n}");
		}

		PropertyNames[PropertyNames.Num()-2] = n"GameAuxSendVolume";
		PropertyNames.Last() = n"ProxyAuxSendVolume";
	}

	EHazeAudioNodeProperty GetValue(int Index) const
	{
		if (Index == PropertyNames.Num() - 1)
			return EHazeAudioNodeProperty::ProxyAuxSendVolume;

		if (Index == PropertyNames.Num() - 2)
			return EHazeAudioNodeProperty::GameAuxSendVolume;

		if (Index != 0)
			return EHazeAudioNodeProperty(Index + 1);

		return EHazeAudioNodeProperty(Index);
	}

	FName GetValue(EHazeAudioNodeProperty Enum) const
	{
		if (Enum == EHazeAudioNodeProperty::ProxyAuxSendVolume)
			return PropertyNames.Last();

		if (Enum == EHazeAudioNodeProperty::GameAuxSendVolume)
			return PropertyNames[PropertyNames.Num()-2];

		if (Enum != EHazeAudioNodeProperty::VoiceVolume)
			return PropertyNames[int(Enum) - 1];

		return PropertyNames[int(Enum)];
	}
}

class UHazeAudioBusMixerDetails : UHazeScriptDetailCustomization
{
	default DetailClass = UHazeAudioBusMixer;

	bool bTriggerRefresh = true;
	bool bHideSettings = false;

	const FName TargetCategory = n"BusMixer Targets";

	FHazeDetailImmediateProperty ImmediateProperty;
	UHazeImmediateDrawer ImmediateDrawer;

	const FHazeAudioBusMixerDetailSetting Settings;

	private UHazeAudioBusMixer CurrentMixer = nullptr;
	
	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		// Hide Targets and then do it all custom.
		// HideProperty(n"Targets");

		ImmediateDrawer = AddImmediateProperty(TargetCategory, "All Targets");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ImmediateDrawer.IsVisible())
			return;
		
		auto BusMixer =  Cast<UHazeAudioBusMixer>(GetCustomizedObject());
		CurrentMixer = BusMixer;

		if (BusMixer == nullptr)
			return;

		auto VerticalBox = ImmediateDrawer.BeginVerticalBox();

		if (VerticalBox.Button("Force Refresh"))
		{
			ForceRefresh();
		}

		auto TargetsScrollBar = VerticalBox.VerticalBox();
			// .SlotMaxHeight(400)
			// .SlotPadding(20, 10)
			// .ScrollBox();

		TSet<UHazeAudioAssetBase> TargetAssets;

		int Index = 0;
		while(Index < BusMixer.Targets.Num())
		{
			auto HorizontalMixer = VerticalBox.HorizontalBox();

			for (int Count=0; Count < 3 && Index < BusMixer.Targets.Num(); ++Index)
			{
				auto& TargetData = BusMixer.Targets[Index];

				if (TargetData.Target != nullptr)
				{
					if (!TargetAssets.Contains(TargetData.Target))
					{
						TargetAssets.Add(TargetData.Target);
					}
					else
					{
						BusMixer.Modify();
						TargetData.Target = nullptr;
						Warning(f"{BusMixer} - You can't have the same target multiple times!");					
					}
				}

				DrawBusTargets(TargetData, HorizontalMixer);
				++Count;
			}
		}

		ImmediateDrawer.End();
	}

	void DrawBusTargets(FHazeAudioBusMixerTarget& TargetData, const FHazeImmediateHorizontalBoxHandle& HorizontalMixer)
	{
		auto BusMixerVerticalBox = HorizontalMixer.VerticalBox();
		{
			auto TargetName = TargetData.Target == nullptr ? "None" : TargetData.Target.Name.ToString();

			BusMixerVerticalBox
				.Text(TargetName)
				.Color(FLinearColor::Purple);
			
			for (int i=0; i < TargetData.Properties.Num(); ++i)
			{
				auto& PropertyTarget = TargetData.Properties[i];

				auto HorizontalBar = BusMixerVerticalBox.HorizontalBox();

				auto NewTargetType = HorizontalBar
					.ComboBox()
					.Items(Settings.PropertyNames)
					.Value(Settings.GetValue(PropertyTarget.Type));

				auto NewTargetTypeValue = Settings.GetValue(NewTargetType.SelectedIndex);
				if (TargetData.Target != nullptr && 
					TargetData.Target.NodeType == EHazeAudioNodeType::Bus && 
					NewTargetTypeValue == EHazeAudioNodeProperty::ProxyAuxSendVolume)
				{
					FMessageDialog::Open(
						EAppMsgType::Ok,
						FText::FromString("ProxyAuxSendVolume isn't allowed on any buses!"),
					);

					if (PropertyTarget.Type == EHazeAudioNodeProperty::ProxyAuxSendVolume)
					{
						NewTargetTypeValue = EHazeAudioNodeProperty::VoiceVolume;
					}
					else
						NewTargetTypeValue = PropertyTarget.Type;
				}

				if (NewTargetTypeValue != PropertyTarget.Type)
				{
					FScopedTransaction Transaction("Modified - Property Type");
					CurrentMixer.Modify();
					PropertyTarget.Type = NewTargetTypeValue;
				}

				auto NewFloatValue = HorizontalBar
					.FloatInput()
					.MinMax(GetMin(PropertyTarget.Type), 
							GetMax(PropertyTarget.Type))
					.Value(PropertyTarget.TargetValue);

				if (NewFloatValue != PropertyTarget.TargetValue)
				{
					FScopedTransaction Transaction("Modified - TargetValue");
					CurrentMixer.Modify();
					PropertyTarget.TargetValue = NewFloatValue;
				}

				if (HorizontalBar.Button("X"))
				{
					FScopedTransaction Transaction("Modified - Removed Property");
					CurrentMixer.Modify();
					TargetData.Properties.RemoveAt(i);
				}
			}

			AddFloatRange(BusMixerVerticalBox, TargetData.FadeInDuration, "Duration - In");
			AddFloatRange(BusMixerVerticalBox, TargetData.FadeOutDuration, "Duration - Out");
			AddFloatRange(BusMixerVerticalBox, TargetData.FadeInCurveExponent, "Pow - In");
			AddFloatRange(BusMixerVerticalBox, TargetData.FadeOutCurveExponent, "Pow - out");
			
			if (BusMixerVerticalBox.Button("Add Property"))
			{
				auto NewType = GetUniqueProperty(TargetData.Properties);

				if (NewType != EHazeAudioNodeProperty::EHazeAudioNodeProperty_MAX)
				{
					TargetData.Properties.Add(FHazeAudioBusMixerPropertyTarget());
					TargetData.Properties.Last().Type = NewType;
				}
			}
		}
	}

	void AddFloatRange(const FHazeImmediateVerticalBoxHandle& Handle, float32& Value, const FString& Label)
	{
		auto NewFloatValue = Handle
			.FloatInput()
			.MinMax(0, 12)
			.Value(Value)
			.Label(Label);

		if (NewFloatValue != Value)
		{
			FScopedTransaction Transaction(f"Modified - {Label}");
			CurrentMixer.Modify();
			Value = NewFloatValue;
			NotifyPropertyModified(CurrentMixer, n"Targets");
		}
	}

	float32 GetMin(EHazeAudioNodeProperty PropertyType)
	{
		switch (PropertyType) {
			case EHazeAudioNodeProperty::VoiceVolume:
			case EHazeAudioNodeProperty::BusVolume: 
			case EHazeAudioNodeProperty::OutputBusVolume:
			case EHazeAudioNodeProperty::MakeUpGain:
			case EHazeAudioNodeProperty::GameAuxSendVolume:
			case EHazeAudioNodeProperty::ProxyAuxSendVolume:
				return -96;
			case EHazeAudioNodeProperty::Pitch: 
				return -4800;
			case EHazeAudioNodeProperty::LPF:
			case EHazeAudioNodeProperty::HPF:
			case EHazeAudioNodeProperty::OutputBusHPF:
			case EHazeAudioNodeProperty::OutputBusLPF:
				return 0;
			default: break;
		}

		return 0;
	}

	float32 GetMax(EHazeAudioNodeProperty PropertyType)
	{
		switch (PropertyType) 
		{
			case EHazeAudioNodeProperty::VoiceVolume:
			case EHazeAudioNodeProperty::BusVolume: 
			case EHazeAudioNodeProperty::OutputBusVolume:
			case EHazeAudioNodeProperty::MakeUpGain:
			case EHazeAudioNodeProperty::GameAuxSendVolume:
			case EHazeAudioNodeProperty::ProxyAuxSendVolume:
				return 24;
			case EHazeAudioNodeProperty::Pitch: 
				return 4800;
			case EHazeAudioNodeProperty::LPF:
			case EHazeAudioNodeProperty::HPF:
			case EHazeAudioNodeProperty::OutputBusHPF:
			case EHazeAudioNodeProperty::OutputBusLPF:
				return 100;
			default: break;
		}

		return 0;
	}

	EHazeAudioNodeProperty GetUniqueProperty(TArray<FHazeAudioBusMixerPropertyTarget>& PropertyArray)
	{
		TSet<int> TakenTypes;
		for (const auto& TargetProperty: PropertyArray)
		{
			TakenTypes.Add(int(TargetProperty.Type));
		}

		for (int i = 0; i < int(EHazeAudioNodeProperty::EHazeAudioNodeProperty_MAX); ++i)
		{
			if (i == int(EHazeAudioNodeProperty::LFE))
				continue;
			
			if (TakenTypes.Contains(i) == false)
				return EHazeAudioNodeProperty(i);
		}

		return EHazeAudioNodeProperty::EHazeAudioNodeProperty_MAX;
	}
}