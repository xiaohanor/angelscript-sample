class AIslandWalkerBreathRingSegment : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Gas;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Gas.OnSystemFinished.AddUFunction(this, n"OnFinished");
	}

	UFUNCTION()
	private void OnFinished(UNiagaraComponent PSystem)
	{
		DestroyActor();
	}

	void Expire()
	{
		Gas.Deactivate();
	}
}