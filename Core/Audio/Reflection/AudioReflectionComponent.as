
struct FChannelRuntimeData
{
	UPROPERTY()
	FHitResult LastHitResult;

	UPROPERTY()
	UPhysicalMaterialAudioAsset AudioMaterial;
	
	UPROPERTY()
	float TraceAlpha;
}

class UAudioReflectionComponent : UHazeAudioReflectionComponent
{
	TArray<FChannelRuntimeData> CacheByTraceType;
	default CacheByTraceType.SetNum(EHazeAudioReflectionTraceType::EHazeAudioReflectionTraceType_MAX);
	bool bZoneWasUpdated = false;

	bool bIsMio;
	UHazeAudioAuxBus CurrentReverbBus;

	UHazeMovementComponent MoveComponentOverride = nullptr;
	UHazeMovementComponent MovementComponent = nullptr;

#if TEST
	const FConsoleVariable CVar_Delay("HazeAudio.Feature_Delay", 1);
#endif
	
	FVector GetWorldUp() const property
	{
		if (MoveComponentOverride != nullptr)
			return MoveComponentOverride.WorldUp;
		
		if (MovementComponent != nullptr)
			return MovementComponent.WorldUp;

		return FVector::UpVector;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		bIsMio = Player.IsMio();

		ResetVolume();
		MovementComponent = UHazeMovementComponent::Get(Player);
	}

	void ResetVolume()
	{
		// NOTE: We might start to fade this out, but for now we reset it.
		AudioReflection::SetReflectionRtpc(bIsMio, EHazeAudioReflectionTraceType::Upwards, EReflectionRtpcType::AuxBusVolume, -200);
		AudioReflection::SetReflectionRtpc(bIsMio, EHazeAudioReflectionTraceType::NorthWest, EReflectionRtpcType::AuxBusVolume, -200);
		AudioReflection::SetReflectionRtpc(bIsMio, EHazeAudioReflectionTraceType::NorthEast, EReflectionRtpcType::AuxBusVolume, -200);
	}

	void SetMovementComponentOverride(UHazeMovementComponent MoveComp)
	{
		MoveComponentOverride = MoveComp;
	}

	void ClearMovementComponentOverride()
	{
		MoveComponentOverride = nullptr;
	}

	void ResetDynamicValues()
	{

	}

	void ResetStaticValues()
	{

	}

	void OnZoneChanged(AHazeAudioZone& CurrentZone,
		const UHazeAudioReflectionDataAsset ReflectionDataAsset)
	{

		if (ReflectionDataAsset == nullptr)
			return;

		bZoneWasUpdated = true;

		CurrentReverbBus = CurrentZone.InternalGetReverbAuxBus();

		FReflectionTraceValues UpwardsChannel;
		ReflectionDataAsset.GetTraceValues(EHazeAudioReflectionTraceType::Upwards, UpwardsChannel);

		// UpdateReflectionChannel won't be called by traces, set all the values
		if (UpwardsChannel.bIsStatic)
		{
			// if any cache needs reset
			ResetDynamicValues();

			// Update all dynamic values.
			for (int i=0; i < int(EHazeAudioReflectionTraceType::EHazeAudioReflectionTraceType_MAX); ++i)
			{
				InternalUpdateReflectionChannel(
					EHazeAudioReflectionTraceType(i),
					UpwardsChannel, // When static this means AllChannels!
					nullptr,
					1.0,
					true
				);
			}	
		}
		// Update the static values
		else {
			// if any cache needs reset
			ResetStaticValues();

		}

		UpdateStaticReflectionChannel(EHazeAudioReflectionTraceType::Upwards, UpwardsChannel);
	}

	// Every channel (trace type) has different rtpcs!
	private void UpdateStaticReflectionChannel(
		const EHazeAudioReflectionTraceType& TraceType,
		const FReflectionTraceValues& TraceValues)
	{
		for	(int i=0; i < TraceValues.StaticRtpcs.Num(); ++i)
		{
			AudioReflection::SetReflectionRtpc(bIsMio, TraceType, TraceValues.StaticRtpcs[i]);
		}
	}

	void UpdateReflectionChannel(
		const EHazeAudioReflectionTraceType& TraceType, 
		const FReflectionTraceValues& TraceValues, 
		const FHitResult& HitResult)
	{
		const auto NewComponent = HitResult.Component;
		const auto& Distance = HitResult.Distance;

		auto& RunetimeCache = CacheByTraceType[int(TraceType)];

		// "ALWAYS" update the dynamic rtpcs
		if (!bZoneWasUpdated &&
			RunetimeCache.LastHitResult.Component == NewComponent &&
			Math::IsNearlyEqual(RunetimeCache.LastHitResult.Distance, Distance, 10.0))
			return;

		bZoneWasUpdated = false;

		if (RunetimeCache.LastHitResult.Component != NewComponent)
		{
			RunetimeCache.AudioMaterial = GetPhysMaterial(NewComponent);
		}
		RunetimeCache.LastHitResult = HitResult;

		// Will decide the values of all dynamic rtpcs
		const float DistanceAlpha = Math::GetPercentageBetweenClamped(TraceValues.MinTraceDistance, TraceValues.MaxTraceDistance, Distance);
		RunetimeCache.TraceAlpha = DistanceAlpha;

		InternalUpdateReflectionChannel(
			TraceType,
			TraceValues,
			RunetimeCache.AudioMaterial,
			DistanceAlpha,
			HitResult.bBlockingHit
		);
	}

	UPhysicalMaterialAudioAsset GetPhysMaterial(const UPrimitiveComponent HitComponent) const
	{
		if (HitComponent == nullptr)
			return nullptr;

		auto MaterialInterface = HitComponent.GetMaterial(0);
		if (MaterialInterface == nullptr)
			return nullptr;
		
		auto PhysMaterial = MaterialInterface.GetPhysicalMaterial();
		if (PhysMaterial == nullptr)
			return nullptr;

		return Cast<UPhysicalMaterialAudioAsset>(PhysMaterial.AudioAsset);
	}

	bool UseMaterialMultiplier(EReflectionRtpcType RtpcType)
	{
		return RtpcType >= EReflectionRtpcType::FeedbackAmount 
			&& RtpcType <= EReflectionRtpcType::LfShelfFilterFrequency;
	}

	private void InternalUpdateReflectionChannel(
		const EHazeAudioReflectionTraceType& TraceType, 
		const FReflectionTraceValues& TraceValues, 
		const UPhysicalMaterialAudioAsset AudioMaterial,
		const float& DistanceAlpha,
		const bool& bBlockingHit
	)
	{
		if (!bBlockingHit
			#if TEST
			|| (CVar_Delay.GetInt() == 0)
			#endif
			)
		{ 
			AudioReflection::SetReflectionRtpc(bIsMio, TraceType, EReflectionRtpcType::AuxBusVolume, -200);
			return;
		}

		float MaterialMultiplier = 1.0;
		if (AudioMaterial != nullptr)
		{
			// Switch for easy additions
			switch(AudioMaterial.HardnessType)
			{
				case EHazeAudioPhysicalMaterialHardnessType::Soft:
				MaterialMultiplier = TraceValues.SoftMaterialFreqMultiplier;
				break;
				case EHazeAudioPhysicalMaterialHardnessType::Hard:
				MaterialMultiplier = TraceValues.HardMaterialFreqMultiplier;
				break;
			}
		}

		for	(int i=0; i < TraceValues.DynamicRtpcs.Num(); ++i)
		{
			float Multiplier = UseMaterialMultiplier(EReflectionRtpcType(i)) ?
				MaterialMultiplier : 1.0;

			AudioReflection::SetReflectionRtpc(this, bIsMio, TraceType, TraceValues.DynamicRtpcs[i], DistanceAlpha, Multiplier);
		}
	}
}