
struct FAudioRatsCritterData
{
	UHazeAudioEmitter Emitter = nullptr;
	UCritterRatComponent Rat = nullptr;
}


UCLASS(Abstract)
class UCreatures_Critters_Rats_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	// If anything else but zero, it will be used to normalize the velocity.
	UPROPERTY()
	float MaxRatSpeed = 0;

	ACritterRats RatsActor;

	TArray<FAudioRatsCritterData> CrittersData;

	// NOTE (GK): Since this SD uses pooled emitters the max distance setting might require a user evaluated distance value!

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		RatsActor = Cast<ACritterRats>(HazeOwner);
	}
	
	void GetPooledEmitter(int EmitterIndex, UCritterRatComponent CritterData)
	{
		auto Params = FHazeAudioEmitterAttachmentParams();
		Params.Owner = this;
		Params.Instigator = this;
		Params.Attachment = CritterData;
		Params.EmitterName = FName(f"RatsCritter_{EmitterIndex}");
		
		CrittersData[EmitterIndex].Emitter = Audio::GetPooledEmitter(Params);
		CrittersData[EmitterIndex].Emitter.AudioComponent.GetObjectVelocity(MaxRatSpeed);

		OnEmitterSetup(CrittersData[EmitterIndex].Emitter);
	}

	void ReturnPooledEmitter(FAudioRatsCritterData& EmitterData)
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
		if (RatsActor.Critters.Num() == 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RatsActor.Critters.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CrittersData.SetNum(RatsActor.Critters.Num());
		
		for (int i=0; i < CrittersData.Num(); ++i)
		{
			auto CritterRatComp = Cast<UCritterRatComponent>(RatsActor.Critters[i]);
			CrittersData[i].Rat = CritterRatComp;
			// CrittersData[i].Rat.OnDirectionChange.AddUFunction(this, n"OnDirectionChange");
			GetPooledEmitter(i, CritterRatComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (int i=0; i < CrittersData.Num(); ++i)
		{
			// CrittersData[i].Rat.OnDirectionChange.UnbindObject(this);
			ReturnPooledEmitter(CrittersData[i]);
		}

		CrittersData.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for (int i=0; i < CrittersData.Num(); ++i)
		{
			OnEmitterUpdate(CrittersData[i].Emitter, CrittersData[i].Emitter.AudioComponent.GetObjectVelocity(MaxRatSpeed));

#if TEST
			if (IsDebugging())
				Debug::DrawDebugSphere(CrittersData[i].Emitter.AudioComponent.WorldLocation, 60, LineColor = FLinearColor::Gray);
#endif
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnEmitterUpdate(UHazeAudioEmitter Emitter, const float32& Velocity) {}

	// UFUNCTION()
	// void OnDirectionChange(int RatIndex)
	// {
	// 	if (!CrittersData.IsValidIndex(RatIndex))
	// 		return;

	// 	devCheck(CrittersData[RatIndex].Rat == RatsActor.Rats[RatIndex]);
	// 	OnRatDirectionChange(CrittersData[RatIndex].Emitter);
	// 	// PrintToScreen(f"Changed direction of {CrittersData[RatIndex].Emitter.Name}");
	// }

	// UFUNCTION(BlueprintEvent)
	// void OnRatDirectionChange(UHazeAudioEmitter Emitter) {}
}