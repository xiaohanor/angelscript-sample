
UCLASS(Abstract)
class UCharacter_Boss_Skyline_MrHammer_Pulse_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPulseAttackFire(){}

	UFUNCTION(BlueprintEvent)
	void OnPulseAttackPrime(){}

	UFUNCTION(BlueprintEvent)
	void OnPulseAttackStartNewWave(){}

	UFUNCTION(BlueprintEvent)
	void OnPulseAttackImpact(FSkylineTorPulseImpactEventData Data){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	bool bHasActivePulses = false;

	ASkylineTor MrHammer;
	private TArray<FAkSoundPosition> PulseSoundPositions;

	UFUNCTION(BlueprintEvent)
	void OnStopActivePulses() {}

	UFUNCTION(BlueprintEvent)
	void OnMusicBeat() {}
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MrHammer = Cast<ASkylineTor>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return MrHammer.PulseComp.bSpawningPulses;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !MrHammer.PulseComp.bSpawningPulses;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Music::Get().OnMainMusicBeat().AddUFunction(this, n"OnMusicBeat");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Music::Get().OnMainMusicBeat().UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<ASkylineTorPulse> Pulses = TListedActors<ASkylineTorPulse>().GetArray();
		const int NumPulses = Pulses.Num();

		if(NumPulses > 0)
		{
			PulseSoundPositions.Empty(NumPulses);
			PulseSoundPositions.SetNum(NumPulses);
			for(int i = 0; i < NumPulses; ++i)
			{
				PulseSoundPositions[i].SetPosition(Pulses[i].ActorLocation);
			}

			DefaultEmitter.SetMultiplePositions(PulseSoundPositions);
			bHasActivePulses = true;
		}
		else if(bHasActivePulses)
		{
			OnStopActivePulses();
			bHasActivePulses = false;
		}
	}
}