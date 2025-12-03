
struct FAudioFrogsCritterData
{
	UHazeAudioEmitter Emitter = nullptr;
	UCritterFrogComponent Frog = nullptr;
	bool bWasInJump = false;
}


UCLASS(Abstract)
class UCreatures_Critters_Frogs_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	// If anything else but zero, it will be used to normalize the velocity.
	UPROPERTY()
	float MaxFrogspeed = 0;

	ACritterFrogs FrogsActor;

	TArray<FAudioFrogsCritterData> CrittersData;

	// NOTE (GK): Since this SD uses pooled emitters the max distance setting might require a user evaluated distance value!

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		FrogsActor = Cast<ACritterFrogs>(HazeOwner);
	}
	
	void GetPooledEmitter(int EmitterIndex, UCritterFrogComponent CritterData)
	{
		auto Params = FHazeAudioEmitterAttachmentParams();
		Params.Owner = this;
		Params.Instigator = this;
		Params.Attachment = CritterData;
		Params.EmitterName = FName(f"FrogsCritter_{EmitterIndex}");
		
		CrittersData[EmitterIndex].Emitter = Audio::GetPooledEmitter(Params);
		CrittersData[EmitterIndex].Emitter.AudioComponent.GetObjectVelocity(MaxFrogspeed);

		OnEmitterSetup(CrittersData[EmitterIndex].Emitter);
	}

	void ReturnPooledEmitter(FAudioFrogsCritterData& EmitterData)
	{
		if (EmitterData.Emitter == nullptr)
				return;

		Audio::ReturnPooledEmitter(this, EmitterData.Emitter);
	}

	
	UFUNCTION(BlueprintEvent)
	void OnEmitterSetup(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (FrogsActor.Critters.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (FrogsActor.Critters.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CrittersData.SetNum(FrogsActor.Critters.Num());
		
		for (int i=0; i < CrittersData.Num(); ++i)
		{
			auto FrogComp = Cast<UCritterFrogComponent>(FrogsActor.Critters[i]);
			CrittersData[i].Frog = FrogComp;
			GetPooledEmitter(i, FrogComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (int i=0; i < CrittersData.Num(); ++i)
		{
			ReturnPooledEmitter(CrittersData[i]);
		}

		CrittersData.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for (int i=0; i < CrittersData.Num(); ++i)
		{
			auto& CritterData = CrittersData[i];
			OnEmitterUpdate(CritterData.Emitter, CritterData.Emitter.AudioComponent.GetObjectVelocity(MaxFrogspeed));

			bool bInAir = CritterData.Frog.bInAir;
			if (CritterData.bWasInJump != bInAir)
			{
				if (CritterData.bWasInJump)
				{
					OnFrogLand(CritterData.Emitter);
				}
				else
				{
					OnFrogJump(CritterData.Emitter);
				}

				CritterData.bWasInJump = bInAir;
			}
#if TEST
			if (IsDebugging())
				Debug::DrawDebugSphere(CritterData.Emitter.AudioComponent.WorldLocation, 60, LineColor = FLinearColor::Gray);
#endif
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnEmitterUpdate(UHazeAudioEmitter Emitter, const float32& Velocity) {}

	UFUNCTION(BlueprintEvent)
	void OnFrogJump(UHazeAudioEmitter Emitter) {}

	UFUNCTION(BlueprintEvent)
	void OnFrogLand(UHazeAudioEmitter Emitter) {}
}