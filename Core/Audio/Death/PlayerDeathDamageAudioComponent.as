struct FPlayerAudioDeathOrDamageData
{
	// RefCount
	TSet<FInstigator> Instigators;

	bool ZeroInstigators() const
	{
		return Instigators.Num() == 0;
	}

	bool CanAttach() const
	{
		return Instigators.Num() == 1;
	}
}

event void FOnNewDamageEffect(UDamageEffect Effect, int Count);
event void FOnNewDeathEffect(UDeathEffect Effect, int Count);

class UPlayerDeathDamageAudioComponent : UActorComponent
{
	TMap<UClass, FPlayerAudioDeathOrDamageData> DeathSoundDefs;
	TMap<UClass, FPlayerAudioDeathOrDamageData> DmgSoundDefs;

	USoundDefContextComponent SoundDefContext;

	FOnNewDeathEffect OnNewDeathEffect;
	FOnNewDamageEffect OnNewDamageEffect;

	access InternalAudio = private, UCharacter_Player_Health_SoundDef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SoundDefContext = USoundDefContextComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintPure)
	int GetNumOfDeathEffects(UHazeSoundDefBase SoundDef)
	{
		return DeathSoundDefs.FindOrAdd(SoundDef.Class).Instigators.Num();
	}

	UFUNCTION(BlueprintPure)
	int GetNumOfDamageEffects(UHazeSoundDefBase SoundDef)
	{
		return DmgSoundDefs.FindOrAdd(SoundDef.Class).Instigators.Num();
	}

	void AttachSoundDef(UDeathEffect DeathEffect, const FSoundDefReference& SoundDefRef)
	{
		int ActiveInstances = 0;
		if (AttachSoundDef(DeathSoundDefs, SoundDefRef, DeathEffect, ActiveInstances))
		{
			OnNewDeathEffect.Broadcast(DeathEffect, ActiveInstances);
		}
	}

	void AttachSoundDef(UDamageEffect DmgEffect, const FSoundDefReference& SoundDefRef)
	{
		int ActiveInstances = 0;
		if (AttachSoundDef(DmgSoundDefs, SoundDefRef, DmgEffect, ActiveInstances))
		{
			OnNewDamageEffect.Broadcast(DmgEffect, ActiveInstances);
		}
	}

	// Always return true if the event should be run.
	private bool AttachSoundDef(
		TMap<UClass, FPlayerAudioDeathOrDamageData>& InMap, 
		const FSoundDefReference& SoundDefRef,
		FInstigator InObject,
		int& OutActiveInstances)
	{
		if (!SoundDefRef.IsValid())
			return false;
		
		auto& Data = InMap.FindOrAdd(SoundDefRef.SoundDef);
		devCheck(!Data.Instigators.Contains(InObject));
		Data.Instigators.Add(InObject);

		if (!Data.CanAttach())
		{
			OutActiveInstances = Data.Instigators.Num();
			return true;
		}

		SoundDefRef.SpawnSoundDefAttached(Owner);
		return true;
	}

	void RemoveSoundDef(UDeathEffect DeathEffect, const FSoundDefReference& SoundDefRef)
	{
		RemoveSoundDef(DeathSoundDefs, SoundDefRef, DeathEffect);
	}

	void RemoveSoundDef(UDamageEffect DmgEffect, const FSoundDefReference& SoundDefRef)
	{
		RemoveSoundDef(DmgSoundDefs, SoundDefRef, DmgEffect);
	}

	private void RemoveSoundDef(
		TMap<UClass, FPlayerAudioDeathOrDamageData>& InMap, 
		const FSoundDefReference& SoundDefRef,
		FInstigator InObject)
	{
		if (!SoundDefRef.IsValid())
			return;
		
		auto& Data = InMap.FindOrAdd(SoundDefRef.SoundDef);
		devCheck(Data.Instigators.Contains(InObject));
		Data.Instigators.Remove(InObject);
		
		if (!Data.ZeroInstigators())
			return;
		
		SoundDefContext.RemoveSoundDefByClass(SoundDefRef.SoundDef);
	}

	access:InternalAudio
	bool AttachInvulnerableSoundDef(FInstigator Instigator, const FSoundDefReference& SoundDefRef)
	{
		if (!SoundDefRef.IsValid())
			return false;
		
		auto& Data = DmgSoundDefs.FindOrAdd(SoundDefRef.SoundDef);
		bool bNotAdded = !Data.Instigators.Contains(Instigator);
		bool bAttach = Data.ZeroInstigators();
		if (bNotAdded)
			Data.Instigators.Add(Instigator);
		
		if (!bAttach)
		{
			OnNewDamageEffect.Broadcast(nullptr, Data.Instigators.Num());
			return bNotAdded;
		}
	
		SoundDefRef.SpawnSoundDefAttached(Owner);
		OnNewDamageEffect.Broadcast(nullptr, Data.Instigators.Num());
		return bNotAdded;
	}

	access:InternalAudio
	void RemoveInvulnerableSoundDef(UObject Instigator, const FSoundDefReference& SoundDefRef)
	{
		RemoveSoundDef(DmgSoundDefs, SoundDefRef, Instigator);
	}
};