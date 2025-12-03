struct FDelayDirectionValues
{
	UPROPERTY()
	TArray<FString> NamesAndValues;
}


class UAudioDebugDelay : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Delay; }

	FString GetTitle() override
	{
		return "Delay";
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		DrawReflectionDelay(DebugManager, Section);
	}

	void DrawReflectionDelay(
		UAudioDebugManager DebugManager,
		const FHazeImmediateSectionHandle Section)
	{
		TMap<FString, float32> Rtpcs;
		if(!DebugManager.GetRTPCs(DebugManager.GetGlobalEmitter(DebugManager), Rtpcs))
			return;

		auto MioBox = Section.VerticalBox();
		auto ZoeBox = Section.VerticalBox();

		TMap<FString, FDelayDirectionValues> MioSortedRtpcs;
		TMap<FString, FDelayDirectionValues> ZoeSortedRtpcs;

		for	(const auto& KeyValuePair: Rtpcs)
		{
			if (!KeyValuePair.Key.StartsWith("Rtpc_Delay_"))
				continue;

			FString StrippedName = KeyValuePair.Key;
			StrippedName.RemoveFromStart("Rtpc_Delay_");

			bool bIsMio = StrippedName.StartsWith("Mio");
			if (bIsMio)
				StrippedName.RemoveFromStart("Mio_");
			else
				StrippedName.RemoveFromStart("Zoe_");

			auto& Map = bIsMio ? MioSortedRtpcs : ZoeSortedRtpcs;
			int32 Index = StrippedName.Find("_");

			FString DirectionName = StrippedName.LeftChop(StrippedName.Len() - Index);
			Map.FindOrAdd(DirectionName)
				.NamesAndValues
				.Add(f"{StrippedName} : {KeyValuePair.Value}");
		}

		if (DebugManager.ReflectionDirectionPrettyNames.Num() != int(EHazeAudioReflectionTraceType::EHazeAudioReflectionTraceType_MAX))
		{
			DebugManager.ReflectionDirectionPrettyNames.SetNum(int(EHazeAudioReflectionTraceType::EHazeAudioReflectionTraceType_MAX));

			for (int j=0; j < int(EHazeAudioReflectionTraceType::EHazeAudioReflectionTraceType_MAX); ++j)
			{
				FString EnumName = (""+EHazeAudioReflectionTraceType(j))
					.RightChop(("EHazeAudioReflectionTraceType::").Len())
					.LeftChop(j > 9 ? 5 : 4);

				DebugManager.ReflectionDirectionPrettyNames[j] = EnumName;
			}
		}

		DrawReflectionComponent(DebugManager, Game::Mio, MioBox, MioSortedRtpcs);
		DrawReflectionComponent(DebugManager, Game::Zoe, ZoeBox, ZoeSortedRtpcs);
	}

	void DrawReflectionComponent(
		UAudioDebugManager DebugManager,
		AHazePlayerCharacter Player,
		const FHazeImmediateVerticalBoxHandle& VerticalBox,
		const TMap<FString, FDelayDirectionValues>& SortedRtpcs)
	{
		if (Player == nullptr)
			return;

		auto AudioComponent = Player.PlayerAudioComponent;
		auto ReverbComponent = AudioComponent.GetReverbComponent();
		auto Zone = ReverbComponent.GetPrioritizedReverbZone();
		auto ReflectionAsset = Zone != nullptr ? Zone.ReflectionAsset : nullptr;

		FLinearColor Color = Player.IsMio() ? FLinearColor::Green : FLinearColor::Red;
		VerticalBox.Text(f"{Player.Name} - REFLECTION ({ReflectionAsset})").Color(Color);

		auto MioReflectionComp = UAudioReflectionComponent::Get(AudioComponent.Owner);
		if (MioReflectionComp == nullptr)
			return;

		for (int j=0; j < int(EHazeAudioReflectionTraceType::EHazeAudioReflectionTraceType_MAX); ++j)
		{
			const auto& DelayReverb = MioReflectionComp.ReflectionReverbByDirection[j];
			const auto& DirectionName = DebugManager.ReflectionDirectionPrettyNames[j];

			VerticalBox
					.SlotPadding(25,0,0,0)
					.Text(DirectionName)
					.Color(Color);

			FDelayDirectionValues Values;
			SortedRtpcs.Find(DirectionName, Values);
			for	(const auto& NameAndValue: Values.NamesAndValues)
			{
				VerticalBox
					.SlotPadding(50,0,0,0)
					.Text(NameAndValue)
					.Color(FLinearColor::Yellow);
			}

			const auto& ChannelRuntimeData = MioReflectionComp.CacheByTraceType[j];
			VerticalBox
				.SlotPadding(50,0,0,0)
				.Text(f"{DirectionName} - Distance : {ChannelRuntimeData.LastHitResult.Distance}, Alpha: {ChannelRuntimeData.TraceAlpha}")
				.Color(FLinearColor::Yellow);

			FString MaterialName = ChannelRuntimeData.AudioMaterial == nullptr ? "None" : ChannelRuntimeData.AudioMaterial.Name.ToString();
			VerticalBox
				.SlotPadding(50,0,0,0)
				.Text(f"{DirectionName} - Material : {MaterialName}")
				.Color(FLinearColor::Yellow);

			FString BusName = DelayReverb.DelayBus != nullptr ? DelayReverb.DelayBus.Name.ToString() : "Unknown";
			VerticalBox
				.SlotPadding(50,0,0,0)
				.Text(f"{BusName} - ReverbSend : {DelayReverb.SendValue}")
				.Color(FLinearColor::Yellow);
		}

		VerticalBox
			.SlotPadding(25,0,0,0)
			.Text("Static")
			.Color(Color);

		FDelayDirectionValues Values;
		SortedRtpcs.Find("Peak", Values);
		for	(const auto& NameAndValue: Values.NamesAndValues)
		{
			VerticalBox
				.SlotPadding(50,0,0,0)
				.Text(NameAndValue)
				.Color(FLinearColor::Yellow);
		}
	}
}