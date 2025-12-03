class ASolarFlareActivateSunFlareVolume : APlayerTrigger
{
	ASolarFlareSun Sun;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Sun = TListedActors<ASolarFlareSun>().GetSingle();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (!Sun.IsSolarFlareWaveActive())
			Sun.ManualActivateSunFlareSequence();
	}
}