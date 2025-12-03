class ASolarFlareAudioLevelScriptActor : AAudioLevelScriptActor
{
	// Look for Sun during tick instead of BeginPlay, to account for level load differences
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().GetSingle();

		if(Sun != nullptr)
		{
			Sun.OnSolarFlareActivateWave.AddUFunction(this, n"OnSunExplode");
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().GetSingle();

		if(Sun != nullptr)
			Sun.OnSolarFlareActivateWave.UnbindObject(this);
	}

	UFUNCTION(BlueprintEvent)
	void OnSunExplode() {}
}