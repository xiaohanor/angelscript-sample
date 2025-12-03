namespace AudioReflection
{
	// This is a shared resource
	struct FReflectionRtpcs
	{
		TArray<FHazeAudioID> UpwardsReflectionRTPCs;
		TArray<FHazeAudioID> NorthWestReflectionRTPCs;
		TArray<FHazeAudioID> NorthEastReflectionRTPCs;

		void AddRtpcs(TArray<FHazeAudioID>& Array,
			const FString& Direction, const FString& Player)
		{
			// NOTE: The order is absolute, if incorrect the system won't work correctly.
			// AuxBusVolume	
			// DelayTime
			// FeedbackAmount
			// HfShelfFilterFrequency
			// LfShelfFilterFrequency
			// ReverbSendLevel
			// PeakFilterFrequency
			// PeakFilterGain
			// FeedbackFilterFrequency
			// FeedbackFilterGain
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_{Direction}_AuxBus_Volume"));
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_{Direction}_DelayTime"));
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_{Direction}_FeedbackAmount"));
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_{Direction}_HfShelf_FilterFreq"));
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_{Direction}_LfShelf_FilterFreq"));
			// We only add this as a filler so the array is valid.
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_{Direction}_Reverb_Send_Level"));
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_Peak_FilterFreq"));
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_Peak_FilterGain"));
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_Feedback_FilterFreq"));
			Array.Add(FHazeAudioID(f"Rtpc_Delay_{Player}_Feedback_FilterGain"));
		}

		FReflectionRtpcs(const FString& PlayerName)
		{
			AddRtpcs(UpwardsReflectionRTPCs, "Upwards", PlayerName);
			AddRtpcs(NorthWestReflectionRTPCs, "NorthWest", PlayerName);
			AddRtpcs(NorthEastReflectionRTPCs, "NorthEast", PlayerName);
		}

		void GetRtpcArray(EHazeAudioReflectionTraceType TraceType, TArray<FHazeAudioID>& OutArray) const
		{
			switch (TraceType)
			{
				case EHazeAudioReflectionTraceType::Upwards:
				OutArray = UpwardsReflectionRTPCs;
				break;
				case EHazeAudioReflectionTraceType::NorthWest:
				OutArray = NorthWestReflectionRTPCs;
				break;
				case EHazeAudioReflectionTraceType::NorthEast:
				OutArray = NorthEastReflectionRTPCs;
				break;
			}
		}
	}

	const FReflectionRtpcs MiosReflectionRtpcs = FReflectionRtpcs("Mio");
	const FReflectionRtpcs ZoesReflectionRtpcs = FReflectionRtpcs("Zoe");

	float GetDynamicRtpcValue(const FReflectionDynamicRtpcData& DynamicRtpc, float Alpha)
	{
		return Math::GetPercentageBetween(DynamicRtpc.Min, DynamicRtpc.Max, Alpha);
	}

	void SetReflectionRtpc(
		const bool& bIsMio,
		const EHazeAudioReflectionTraceType& TraceType,
		const EReflectionRtpcType& RtpcType,
		const float& Value)
	{
		TArray<FHazeAudioID> RtpcArray;
		if (bIsMio)
			MiosReflectionRtpcs.GetRtpcArray(TraceType, RtpcArray);
		else 
			ZoesReflectionRtpcs.GetRtpcArray(TraceType, RtpcArray);

		AudioComponent::SetGlobalRTPC(RtpcArray[RtpcType], Value);
	}

	void SetReflectionRtpc(
		UAudioReflectionComponent Component,
		const bool& bIsMio,
		const EHazeAudioReflectionTraceType& TraceType, 
		const FReflectionDynamicRtpcData& DynamicRtpc, 
		const float& Alpha,
		const float& Multiplier)
	{
		const float Value = Math::Lerp(DynamicRtpc.Min, DynamicRtpc.Max, Alpha) * Multiplier;
		if (DynamicRtpc.RtpcType == EReflectionRtpcType::ReverbSendLevel)
		{
#if EDITOR
			// Can't set these values during simulation, since they would affect the exact same (GLOBAL) bus.
			if (UHazeAudioNetworkDebugManager::IsNetworkSimulating() && !Component.HasControl())
			{
				return;
			}
#endif
			Component.SetReflectionSendToReverbBus(TraceType, Component.CurrentReverbBus, Value);
			return;		
		}

		TArray<FHazeAudioID> RtpcArray;
		if (bIsMio)
			MiosReflectionRtpcs.GetRtpcArray(TraceType, RtpcArray);
		else 
			ZoesReflectionRtpcs.GetRtpcArray(TraceType, RtpcArray);

		AudioComponent::SetGlobalRTPC(RtpcArray[DynamicRtpc.RtpcType], Value);
	}

	void SetReflectionRtpc(
		const bool& bIsMio,
		const EHazeAudioReflectionTraceType& TraceType, 
		const FReflectionStaticRtpcData& StaticRtpc)
	{
		TArray<FHazeAudioID> RtpcArray;
		if (bIsMio)
			MiosReflectionRtpcs.GetRtpcArray(TraceType, RtpcArray);
		else 
			ZoesReflectionRtpcs.GetRtpcArray(TraceType, RtpcArray);

		AudioComponent::SetGlobalRTPC(RtpcArray[StaticRtpc.RtpcType], StaticRtpc.Value);
	}

	// HELPER FUNCTIONS

	UFUNCTION(BlueprintPure)
	void GetRuntimeReflectionData(UAudioReflectionComponent ReflectionComponent, EHazeAudioReflectionTraceType TraceType, FChannelRuntimeData&out Data)
	{
		if (ReflectionComponent == nullptr)
			return;

		Data = ReflectionComponent.CacheByTraceType[TraceType];
	}

	UFUNCTION(BlueprintPure)
	void GetReflectionTraceAlpha(UAudioReflectionComponent ReflectionComponent, EHazeAudioReflectionTraceType TraceType, float& TraceAlpha)
	{
		if (ReflectionComponent == nullptr)
			return;

		TraceAlpha = ReflectionComponent.CacheByTraceType[TraceType].TraceAlpha;
	}

	UFUNCTION(BlueprintPure)
	void GetRuntimeReflectionHitResultDistance(UAudioReflectionComponent ReflectionComponent, EHazeAudioReflectionTraceType TraceType, float&out HitDistance)
	{
		if (ReflectionComponent == nullptr)
			return;

		HitDistance = ReflectionComponent.CacheByTraceType[TraceType].LastHitResult.Distance;
	}

	UFUNCTION(BlueprintPure)
	bool IsTraceBlocking(UAudioReflectionComponent ReflectionComponent, EHazeAudioReflectionTraceType TraceType, float&out HitDistance)
	{
		if (ReflectionComponent == nullptr)
			return false;

		const auto HitResult = ReflectionComponent.CacheByTraceType[TraceType].LastHitResult;
		HitDistance = HitResult.Distance;
		return HitResult.bBlockingHit;
	}

}