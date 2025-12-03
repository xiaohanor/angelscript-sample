struct FGiantsAudioSocketLocations
{
	UPROPERTY(EditDefaultsOnly, Meta = (GetOptions = GetGiantsAudioSocketNames))
	TArray<FName> Sockets;
}

UCLASS(Abstract)
class UCharacter_Creature_NPC_Giant_SoundDef : USoundDefBase
{
	UPROPERTY(BlueprintReadOnly, Meta = (GetOptions = GetEmitterNames))
	TMap<FName, FGiantsAudioSocketLocations> EmitterLocations;
	private TMap<UHazeAudioEmitter, FGiantsAudioSocketLocations> EmitterToLocations;

	const FHazeAudioID SharedDistanceRTPCID = FHazeAudioID("Rtpc_Shared_Distance");

	ATheGiant Giant;

	#if EDITOR
	UFUNCTION()
	TArray<FString> GetGiantsAudioSocketNames() const
	{
		TArray<FString> SocketNamesAsStr;

		for(auto SocketName : GiantsAudio::GetSocketNames())
		{
			SocketNamesAsStr.Add(SocketName.ToString());
		}	

		return SocketNamesAsStr;
	}

	UFUNCTION()
	TArray<FString> GetEmitterNames() const
	{
		TArray<FString> EmitterNamesAsStr;

		for(auto EmitterName : UHazeAudioEditorUtils::GetSoundDefEmitterNames(this))
		{
			EmitterNamesAsStr.Add(EmitterName.ToString());
		}

		return EmitterNamesAsStr;
	}
	#endif	

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Giant = Cast<ATheGiant>(HazeOwner);

		for(auto& Pair : EmitterLocations)
		{
			FName EmitterName = Pair.Key;
			UHazeAudioEmitter SocketEmitter = nullptr;
			
			for(auto AudioComp : AudioComponents)
			{
				for(auto& EmitterPair : AudioComp.EmitterPairs)
				{
					if(EmitterPair.Name == EmitterName)
					{
						SocketEmitter = EmitterPair.Emitter;
						break;						
					}
				}
			}		

			if(SocketEmitter != nullptr)
			{	
				FGiantsAudioSocketLocations SocketLocations = Pair.Value;
				EmitterToLocations.Add(SocketEmitter, SocketLocations);		
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		#if EDITOR
		float ShortestEmitterListernerDistance = MAX_flt;
		#endif

		for(auto& Pair : EmitterToLocations)
		{
			UHazeAudioEmitter Emitter = Pair.Key;
			FGiantsAudioSocketLocations SocketData = Pair.Value;

			TArray<FAkSoundPosition> SoundPositions;
			for(int i = 0; i < SocketData.Sockets.Num(); ++i)
			{
				auto SocketName = SocketData.Sockets[i];
				if(SocketName != NAME_None)
					SoundPositions.Add(FAkSoundPosition(Giant.Mesh.GetSocketLocation(SocketName)));
			}

			if(SoundPositions.Num() > 1)
				Emitter.AudioComponent.SetMultipleSoundPositions(SoundPositions, AkMultiPositionType::MultiSources);
			else
				Emitter.AudioComponent.SetWorldLocation(SoundPositions[0].Position);

			float DistanceToClosestListener = Emitter.AudioComponent.GetClosestListenerDistance();
			float AttenuationDistance = Emitter.GetAttenuationScaling();
			if(AttenuationDistance == 0)
				continue;

			const float NormalizedDistance = Math::Clamp(DistanceToClosestListener / AttenuationDistance, 0, 1);
			Emitter.SetRTPC(SharedDistanceRTPCID, NormalizedDistance, 0);

		#if EDITOR
			ShortestEmitterListernerDistance = Math::Min(ShortestEmitterListernerDistance, NormalizedDistance);
		#endif
		}

		#if EDITOR
			auto CustomLog = TEMPORAL_LOG("Audio/Giants");
			auto Group = CustomLog.Page(Giant.GetActorLabel());
			Group.Value("Normalized Distance To Closest Emitter<>Listener: ", ShortestEmitterListernerDistance);
		#endif

	}
}
