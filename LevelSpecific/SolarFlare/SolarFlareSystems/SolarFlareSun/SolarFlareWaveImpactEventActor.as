event void FOnSolarWaveImpactEventActorTriggered();

event void FOnSolarWaveImpactImpostersTriggered(float Duration);

class ASolarFlareWaveImpactEventActor : AHazeActor
{
	UPROPERTY()
	FOnSolarWaveImpactEventActorTriggered OnSolarWaveImpactEventActorTriggered;

	// Only for audio purposes.
	UPROPERTY()
	FOnSolarWaveImpactImpostersTriggered OnSolarWaveImpactImpostersTriggered;

	UPROPERTY()
	float LastImposterDuration = 0;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	ASolarFlareSun Sun;

	private bool bNewActive;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Sun == nullptr)
		{
			Sun = TListedActors<ASolarFlareSun>().GetSingle();
			Sun.WaveImpactActors.Add(this);
		}
	}

	void SolarFlareFireDonutActivated()
	{
		bNewActive = true;
	}

	void RunBroadcastCheck(ASolarFlareFireDonutActor FireDonut)
	{
		if (bNewActive)
		{
			bNewActive = false;
			OnSolarWaveImpactEventActorTriggered.Broadcast();
		}
	}

	UFUNCTION()
	ASolarFlareFireDonutActor GetDonutWave()
	{
		if (Sun == nullptr)
			Sun = TListedActors<ASolarFlareSun>().GetSingle();	

		if (Sun.CurrentFireDonut != nullptr)
			return Sun.CurrentFireDonut;

		return nullptr;
	}
}