
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_WaveAttack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void WaveSlashAttackSpawned(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter WaveMultiEmitter;

	APrisonBoss DarkMio;

	UPROPERTY(BlueprintReadOnly)
	float CrowdControlValueAverage = 1.0;

	private bool bIsInDelayedActivation = false;
	private float DelayedDeactivationTimer = 3.0;
	private bool bDelayedActivationComplete = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkMio.AnimationData.bIsEnteringWaveSlash;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return bDelayedActivationComplete;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = DarkMio;
		
		if(EmitterName == n"WaveMultiEmitter")
			bUseAttach = false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DelayedDeactivationTimer = 3.0;
		bIsInDelayedActivation = false;
		bDelayedActivationComplete = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		auto ActiveWaves = TListedActors<APrisonBossWaveSlashActor>().GetArray();
		const int WaveCount = ActiveWaves.Num();
		float CrowdControlAveraged = 1.0;

		if(WaveCount > 0)
		{
			TArray<FAkSoundPosition> WaveSoundPositions;

			WaveSoundPositions.SetNum(WaveCount);


			for(int i = 0; i < WaveCount; ++i)
			{
				auto Wave = ActiveWaves[i];
				WaveSoundPositions[i].SetPosition(Wave.ActorCenterLocation);

				CrowdControlAveraged += Wave.CrowdControlComp.GetCrowdControlValue();
			}

			CrowdControlValueAverage = Math::Saturate(CrowdControlAveraged / WaveCount);
			WaveMultiEmitter.SetMultiplePositions(WaveSoundPositions, AkMultiPositionType::MultiSources);
		}
		else
		{
			CrowdControlValueAverage = 1.0;
		}

		if(DarkMio.AnimationData.bIsExitingWaveSlash && !bIsInDelayedActivation)
			bIsInDelayedActivation  = true;

		if(bIsInDelayedActivation)
		{
			DelayedDeactivationTimer -= DeltaSeconds;
			bDelayedActivationComplete = (DelayedDeactivationTimer <= 0.0);	
		}
	}
}