class AGravityBikeFreeImpactDestructible : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactResponseComp.OnImpact.AddUFunction(this, n"HandleImpact");
	}

	UFUNCTION()
	private void HandleImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		BP_OnImpact();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpact() { }
};