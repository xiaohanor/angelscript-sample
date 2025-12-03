class AGameShowArenaRandomExplosion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void StartExploding()
	{
		Timer::SetTimer(this, n"Explode", Math::RandRange(1, 4), true, Math::RandRange(1, 4));
	}

	UFUNCTION()
	private void Explode()
	{
		VFX.Activate();
	}
};