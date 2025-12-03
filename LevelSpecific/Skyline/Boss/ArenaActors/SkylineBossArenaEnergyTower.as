class ASkylineBossArenaEnergyTower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactResponseComp;
	default ImpactResponseComp.bIgnoreAfterImpact = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactResponseComp.OnImpact.AddUFunction(this, n"HandleImpact");
	}

	UFUNCTION()
	private void HandleImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		FVector Direction = (GravityBike.ActorLocation - Data.ImpactPoint).GetSafeNormal();
		GravityBike.GetDriver().KillPlayer(FPlayerDeathDamageParams(Direction, 10.0), DeathEffect);
	}
};