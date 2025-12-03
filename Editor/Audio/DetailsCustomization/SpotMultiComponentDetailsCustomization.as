#if EDITOR
class USpotMultiModeDetails : UHazeScriptDetailCustomization
{
	default DetailClass = USpotSoundMultiComponent;

	bool bPreviousEmitterMode = false;
	TSubclassOf<UHazeSoundDefBase> PreviousSelection = nullptr;
	
	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		auto MultiComponent = Cast<USpotSoundMultiComponent>(GetCustomizedObject());

		bPreviousEmitterMode = MultiComponent.bMultipleEmitterMode;

		const auto SpotParent = MultiComponent.ParentSpot != nullptr ? MultiComponent.ParentSpot : Cast<USpotSoundComponent>(UHazeAudioEditorUtils::GetSubObject(Cast<UClass>(MultiComponent.Outer), USpotSoundComponent));
		if (SpotParent != nullptr)
			PreviousSelection = SpotParent.AssetData.GetSoundDefAsset().SoundDef;

		if (PreviousSelection != nullptr)
		{
			auto SoundDefEmitterDatas = SoundDef::GetSoundDefEmitters(PreviousSelection.Get());
			if (SoundDefEmitterDatas.Num() != MultiComponent.MultiEmitters.Num())
			{
				MultiComponent.OnSoundDefChanged(SpotParent);
			}
			else
			{	
				bool bSoundDefChanged = false;
				for (auto MultiEmitter: MultiComponent.MultiEmitters)
				{
					if (!MultiEmitter.bSoundDefControlled)
					{
						bSoundDefChanged = true;
						break;
					}
				}

				if (bSoundDefChanged)
					MultiComponent.OnSoundDefChanged(SpotParent);
			}
		}

		if (bPreviousEmitterMode && MultiComponent.EmitterSettings.Num() != MultiComponent.MultiEmitters.Num())
		{
			MultiComponent.EmitterSettings.SetNum(MultiComponent.MultiEmitters.Num());
		}
		else if (!bPreviousEmitterMode)
		{
			MultiComponent.EmitterSettings.Empty();
		}

		for (int i=0; i < MultiComponent.MultiEmitters.Num(); ++i)
		{
			if (!MultiComponent.MultiEmitters[i].bSoundDefControlled && MultiComponent.MultiEmitters[i].EmitterName == n"")
			{
				MultiComponent.MultiEmitters[i].Transform = MultiComponent.RelativeTransform;
				MultiComponent.MultiEmitters[i].EmitterName = FName("Emitter_0"+i);
			}
			// VALIDATE Scale.
			else if (MultiComponent.MultiEmitters[i].Transform.Scale3D == FVector::ZeroVector)
			{
				MultiComponent.MultiEmitters[i].Transform.Scale3D = FVector::OneVector;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		auto MultiComponent = Cast<USpotSoundMultiComponent>(GetCustomizedObject());

		bool bEmitterMode = MultiComponent.bMultipleEmitterMode;
		if (bPreviousEmitterMode != bEmitterMode)
		{
			bPreviousEmitterMode = bEmitterMode;
			ForceRefresh();
		}

		const auto SpotParent = MultiComponent.ParentSpot != nullptr ? MultiComponent.ParentSpot : Cast<USpotSoundComponent>(UHazeAudioEditorUtils::GetSubObject(Cast<UClass>(MultiComponent.Outer), USpotSoundComponent));
		if (SpotParent == nullptr)
			return;

		auto AssetSelection = SpotParent.AssetData.GetSoundDefAsset().SoundDef;

		if (AssetSelection != PreviousSelection)
		{
			MultiComponent.OnSoundDefChanged(SpotParent);
		}
	}
}
#endif