struct FSpotSoundMultiEmitter
{
	UPROPERTY(EditAnywhere)
	FTransform Transform = FTransform(FQuat::Identity, FVector::ZeroVector, FVector::OneVector);

	UPROPERTY(EditConst)
	bool bSoundDefControlled = false;

	UPROPERTY(EditAnywhere, DisplayName = "Name", Meta = (EditCondition = "!bSoundDefControlled"))
	FName EmitterName;

	#if EDITOR
	UPROPERTY(EditAnywhere)
	FLinearColor Color = FLinearColor::MakeRandomColor();
	#endif

	// Runtime data
	UPROPERTY(NotVisible)
	UHazeAudioComponent AudioComponent;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter Emitter;
	//~

	FSpotSoundMultiEmitter() {}

	FSpotSoundMultiEmitter(FTransform InitialTransform, FName InitialName)
	{
		Transform = InitialTransform;
		EmitterName = InitialName;
	}
};

class USpotSoundMultiComponent : USpotSoundModeComponent
{
	default SpotMode = EHazeSpotSoundMode::Multi;

	UPROPERTY(EditAnywhere, DisplayName = "Positions")
	TArray<FSpotSoundMultiEmitter> MultiEmitters;
	default MultiEmitters.Add(FSpotSoundMultiEmitter(RelativeTransform, n"Emitter_01"));

	UPROPERTY(EditAnywhere)
	bool bMultipleEmitterMode = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bMultipleEmitterMode", EditConditionHides = true))
	TArray<FSpotSoundEmitterSettings> EmitterSettings;

#if EDITOR
	void OnModeAdded(USpotSoundComponent Spot) override
	{
		OnSoundDefChanged(Spot);
	}

	void OnSoundDefChanged(const USpotSoundComponent InSpot)
	{
		const USpotSoundComponent Spot = InSpot;
		if (Spot == nullptr && ParentSpot != nullptr)
			Spot = ParentSpot;

		if (Spot == nullptr)
			return;
		
		FSoundDefReference SoundDefData;
		UHazeAudioEvent Event = nullptr;
		Spot.AssetData.GetSoundAsset(Event, SoundDefData);

		if (SoundDefData.SoundDef != nullptr)
		{
			auto SoundDefEmitterDatas = SoundDef::GetSoundDefEmitters(SoundDefData.SoundDef.Get());

			int StartIndex = Math::Min(0, MultiEmitters.Num()-1);
			MultiEmitters.SetNum(SoundDefEmitterDatas.Num());

			for(int i=0; i < MultiEmitters.Num(); ++i)
			{
				MultiEmitters[i].EmitterName = SoundDefEmitterDatas[i].AudioCompName;
				if (i >= StartIndex)
				{
					// The transform will have valid default values.
					MultiEmitters[i].Transform.SetLocation(Math::GetRandomPointInSphere() * 500);
				}
				MultiEmitters[i].bSoundDefControlled = true;
			}
		}
		else if (Event != nullptr)
		{
			for(int i=0; i < MultiEmitters.Num(); ++i)
			{
				MultiEmitters[i].bSoundDefControlled = false;
			}

			if (bMultipleEmitterMode)
				EmitterSettings.SetNum(MultiEmitters.Num());
		}

	}
#endif

	// Used by multi components with bMultipleEmitterMode == true

	UHazeAudioEvent GetSettingsEvent(const FSpotSoundEmitterSettings& Settings)
	{
		// If OverrideDefaultEvent is null use parent instead.
		if (Settings.bAllowEventOverride || Settings.OverrideDefaultEvent == nullptr)
			return ParentSpot.Event;

		return Settings.OverrideDefaultEvent;
	}

	void InternalStartEmitter(int Index)
	{
		auto& PositionData = MultiEmitters[Index];
		auto& EmitterSetting = EmitterSettings[Index];

		// Assume it's already started
		if (PositionData.AudioComponent != nullptr)
		{
			return;
		}

		auto AudioComponent = Audio::GetPooledAudioComponent(FHazeAudioPoolComponentParams());
		PositionData.AudioComponent = AudioComponent;
		PositionData.Emitter = AudioComponent.GetEmitter(this, PositionData.EmitterName);

		ParentSpot.SetupEmitter(EmitterSetting, PositionData.Emitter, AudioComponent);

		// Legacy fix for saved invalid scale.
		if (PositionData.Transform.Scale3D == FVector::ZeroVector)
		{
			PositionData.Transform.Scale3D = FVector::OneVector;
		}

		FTransform EmitterWorldTransform = FTransform(
			WorldTransform.TransformRotation(PositionData.Transform.Rotation),
			WorldTransform.TransformPosition(PositionData.Transform.Location),
			WorldTransform.Scale3D * PositionData.Transform.Scale3D
		);

		AudioComponent.SetWorldTransform(EmitterWorldTransform);
		
		if (EmitterSetting.bPlayOnStart)
		{
			PositionData.Emitter.PostEvent(GetSettingsEvent(EmitterSetting), PostType = EHazeAudioEventPostType::Ambience);
		}
	}

	void InternalStopEmitter(int Index)
	{
		auto& PositionData = MultiEmitters[Index];

		// Can't be playing
		if (PositionData.AudioComponent == nullptr)
			return;

		const auto& EmitterSetting = EmitterSettings[Index];
		
		if (EmitterSetting.FadeOut > 0)
			PositionData.Emitter.StopEvent(GetSettingsEvent(EmitterSetting), EmitterSetting.FadeOut * 1000);
		
		Audio::ReturnPooledAudioComponent(PositionData.AudioComponent);
		PositionData.AudioComponent = nullptr;
	}

	//

	void Start() override
	{
		if (ParentSpot.SoundDef.SoundDef != nullptr)
		{
			FSpawnSoundDefSpotSoundParams Params;
			Params.SpotParent = Cast<AHazeActor>(GetOwner());
			Params.SoundDefRef = ParentSpot.SoundDef;
			Params.EmitterDatas.SetNum(MultiEmitters.Num());
			
			for(int i=0; i < MultiEmitters.Num(); ++i)
			{
				auto EmitterPosition = MultiEmitters[i];
				auto& EmitterData = Params.EmitterDatas[i];

				EmitterData.AudioCompName = EmitterPosition.EmitterName;

				// Let's assume we only have zero vectors due to legacy. See fix in InternalStartEmitter
				// devCheck(EmitterPosition.Transform.Scale3D != FVector::ZeroVector, f"MultiSpot [{GetOwner()}-{EmitterData.AudioCompName}] - ZeroVector is not allowed for any scaling of SceneComponents!");
				if (EmitterPosition.Transform.Scale3D == FVector::ZeroVector)
				{
					EmitterPosition.Transform.Scale3D = FVector::OneVector;
				}

				FTransform EmitterWorldTransform = FTransform(
					WorldTransform.TransformRotation(EmitterPosition.Transform.Rotation),
					WorldTransform.TransformPosition(EmitterPosition.Transform.Location),
					WorldTransform.Scale3D * EmitterPosition.Transform.Scale3D,
				);

				EmitterData.bUseWorldTransform = true;
				EmitterData.WorldTransform = EmitterWorldTransform;
			}

			if(ParentSpot.bLinkToZone)
			{
				Params.LinkedOcclusionZone = ParentSpot.LinkedZone;
			}
			
			Params.bLinkedZoneFollowRelevance = ParentSpot.bLinkToZone && ParentSpot.bLinkedZoneFollowRelevance;

			SoundDef::SpawnSoundDefSpot(Params);
		}
		else {
			if (!bMultipleEmitterMode)
			{
				ParentSpot.GetAudioComponentAndEmitter(ParentSpot.Settings, false);
				ParentSpot.SetupEmitter(ParentSpot.Settings, ParentSpot.Emitter, nullptr);
				ParentSpot.Emitter.PostEvent(ParentSpot.Event, PostType = EHazeAudioEventPostType::Ambience);

				TArray<FAkSoundPosition> Positions;
				Positions.SetNum(MultiEmitters.Num());
				for(int i=0; i < MultiEmitters.Num(); ++i)
				{
					Positions[i] = FAkSoundPosition(WorldTransform.TransformPosition(MultiEmitters[i].Transform.Location));
				}

				ParentSpot.Emitter.AudioComponent.SetMultipleSoundPositions(Positions);
			}
			else {
				check(MultiEmitters.Num() == EmitterSettings.Num());

				for(int i=0; i < MultiEmitters.Num(); ++i)
				{
					if (!EmitterSettings[i].bPlayOnStart)
						continue;

					InternalStartEmitter(i);
				}
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void StartEmitter(FName Emitter)
	{
		for(int i=0; i < MultiEmitters.Num(); ++i)
		{
			if (MultiEmitters[i].EmitterName != Emitter)
				continue;

			InternalStartEmitter(i);
			break;
		}
	}

	UFUNCTION(BlueprintCallable)
	void StopEmitter(FName Emitter)
	{
		for(int i=0; i < MultiEmitters.Num(); ++i)
		{
			if (MultiEmitters[i].EmitterName != Emitter)
				continue;

			InternalStopEmitter(i);
			break;
		}
	}

	void Stop() override
	{
		if (!bMultipleEmitterMode)
		{
			if (ParentSpot.Settings.FadeOut > 0)
				ParentSpot.Emitter.StopEvent(ParentSpot.Event, ParentSpot.Settings.FadeOut * 1000);
			ParentSpot.ReturnAudioComponentAndEmitter();
		}
		else {
			check(MultiEmitters.Num() == EmitterSettings.Num());

			for(int i=0; i < MultiEmitters.Num(); ++i)
			{
				InternalStopEmitter(i);
			}
		}
	}
}