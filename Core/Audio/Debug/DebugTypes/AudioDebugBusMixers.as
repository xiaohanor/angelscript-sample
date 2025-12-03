class UAudioDebugBusMixers : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::BusMixers; }
	
	FString GetTitle() override
	{
		return "BusMixers";
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		// auto BorderColor = FLinearColor::Black;
		// BorderColor.A = 0.2;

		// auto GlobalSection = Section
		// 	.Section("Global")
		// 	.Color(BorderColor);

		TArray<UHazeAudioBusMixer> ActiveBusMixers;
		if (DebugManager.GetActiveBusMixers(ActiveBusMixers))
		{
			auto VLBox = Section.VerticalBox();
			VLBox
				.SlotPadding(10,0,0,0)
				.Text("ActiveBusMixers")
				.Color(FLinearColor::Purple);

			for (auto BusMixer: ActiveBusMixers)
			{
				if (BusMixer == nullptr)
					continue;
				
				VLBox
					.SlotPadding(25,0,0,0)
					.Text(BusMixer.GetName().ToString())
					.Color(FLinearColor::Green);
			}
		}

		TArray<FHazeAudioNodePropertyCache> GlobalProperties;
		if(DebugManager.GetGlobalProperties(GlobalProperties))
		{
			auto VLBox = Section.VerticalBox();

			for	(const auto& PropertySet: GlobalProperties)
			{
				if (!PropertySet.AudioNode.IsValid())
					continue;

				FString NameOfTheNode = PropertySet.AudioNode.Get().Name.ToString();

				if (DebugManager.IsFiltered(NameOfTheNode, false, EDebugAudioFilter::BusMixers))
					continue;

				VLBox
					.SlotPadding(10,0,0,0)
					.Text(NameOfTheNode)
					.Color(FLinearColor::Purple);

				for(int i=0; i < PropertySet.Properties.Num(); ++i)
				{
					if (Math::IsNearlyZero(PropertySet.Properties[i].Value))
						continue;

					auto PropertyType = GetValue(i);
					VLBox
						.SlotPadding(25,0,0,0)
						.Text(f"{PropertyType :n} : {PropertySet.Properties[i].Value:<2}")
						.Color(FLinearColor::Yellow);

				}
			}
		}
	}

	EHazeAudioNodeProperty GetValue(int Index) const
	{
		if (Index == 10)
			return EHazeAudioNodeProperty::ProxyAuxSendVolume;

		if (Index == 9)
			return EHazeAudioNodeProperty::GameAuxSendVolume;

		if (Index != 0)
			return EHazeAudioNodeProperty(Index + 1);

		return EHazeAudioNodeProperty(Index);
	}
}