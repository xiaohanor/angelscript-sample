class ALightBirdActivatedParent : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	TArray<UTargetableComponent> Targetables;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(Targetables);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(0.0, 100.0 * DeltaSeconds, 0.0));
	}

	void Enable()
	{
		for (auto Targetable : Targetables)
		{
			Targetable.Enable(this);
		}			
	}

	void Disable()
	{
		for (auto Targetable : Targetables)
		{
			Targetable.Disable(this);
		}
	}
}