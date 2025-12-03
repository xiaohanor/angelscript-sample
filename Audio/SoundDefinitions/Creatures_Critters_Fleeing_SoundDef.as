
struct FAudioFleeingCritterData
{
	UHazeAudioEmitter Emitter = nullptr;

	bool bNotifiedOnEnd = false;
}

UCLASS(Abstract)
class UCreatures_Critters_Fleeing_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ACritterFleeing CritterActor;

	private int CrittersRemaining = 0;
	private bool bSetInitialPositions = false;

	TArray<FAkSoundPosition> StationaryCritters;
	TArray<FAudioFleeingCritterData> FleeingCritters;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter StationaryEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		CritterActor = Cast<ACritterFleeing>(HazeOwner);

		CrittersRemaining = CritterActor.CritterCount;
		StationaryCritters.SetNum(CritterActor.CritterCount);
		FleeingCritters.SetNum(CritterActor.CritterCount);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CrittersRemaining > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CrittersRemaining == 0)
			return true;

		return false;
	}
	
	UFUNCTION(BlueprintPure)
	int OriginalCritterCount() const
	{
		return CritterActor.CritterCount;
	}

	UFUNCTION(BlueprintPure)
	int CurrentCritterCount() const
	{
		return CrittersRemaining;
	}

	void GetPooledEmitter(int EmitterIndex, const FFleeingCritter& CritterData)
	{
		auto Params = FHazeAudioEmitterAttachmentParams();
		Params.Owner = this;
		Params.Instigator = this;
		Params.Attachment = CritterData.MeshComp;
		Params.EmitterName = FName(f"FleeingCritter_{EmitterIndex}");
		
		FleeingCritters[EmitterIndex].Emitter = Audio::GetPooledEmitter(Params);
	}

	void ReturnPooledEmitter(FAudioFleeingCritterData& EmitterData)
	{
		if (EmitterData.Emitter == nullptr)
				return;

		Audio::ReturnPooledEmitter(this, EmitterData.Emitter);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto& EmitterData : FleeingCritters)
		{
			ReturnPooledEmitter(EmitterData);
			// Reset
			EmitterData.bNotifiedOnEnd = false;
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnCritterFleeingStart(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintEvent)
	void OnCritterFleeingEnd(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintEvent)
	void OnNoStationaryCritterLeft() {}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Track all critters, how many are stationary and how many are fleeing currently.
		
		int StationaryIndex = 0;
		int FleeingCount = 0;
		int CrittersAlive = 0;

		const auto& Critters = CritterActor.Critters;
		for (int i=0; i < Critters.Num(); ++i)
		{
			const auto& CritterData = Critters[i];
			if(CritterData.MeshComp == nullptr || CritterData.MeshComp.IsBeingDestroyed())
			{
				if (FleeingCritters[i].Emitter != nullptr)
				{
					if (FleeingCritters[i].bNotifiedOnEnd == false)
					{
						FleeingCritters[i].bNotifiedOnEnd = true;
						OnCritterFleeingEnd(FleeingCritters[i].Emitter);
					}

					// We wait until there are no events playing.
					if (FleeingCritters[i].Emitter.IsPlaying() == false)
						ReturnPooledEmitter(FleeingCritters[i]);
				}
			
				continue;
			}

			++CrittersAlive;

			if (CritterData.bFleeing)
			{
				if (FleeingCritters[i].Emitter == nullptr)
				{
					GetPooledEmitter(i, CritterData);
					OnCritterFleeingStart(FleeingCritters[i].Emitter);
				}
				++FleeingCount;
			}
			else
			{
				StationaryCritters[StationaryIndex].SetPosition(CritterData.MeshComp.WorldLocation);
				++StationaryIndex;
			}

			#if TEST
			if (IsDebugging())
			{
				Debug::DrawDebugSphere(CritterData.MeshComp.WorldLocation, CritterActor.Radius * CritterActor.Scale, LineColor = CritterData.bFleeing ? FLinearColor::Green : FLinearColor::Gray);
			}
			#endif
		}

		// Clean up any now fleeing
		if (StationaryIndex < StationaryCritters.Num())
		{
			StationaryCritters.SetNum(StationaryIndex);
			StationaryEmitter.AudioComponent.SetMultipleSoundPositions(StationaryCritters);

			if (StationaryCritters.Num() == 0)
				OnNoStationaryCritterLeft();

		}
		else if (!bSetInitialPositions)
		{
			bSetInitialPositions = true;
			StationaryEmitter.SetMultiplePositions(StationaryCritters);
		}

		CrittersRemaining = CrittersAlive;
	}
}