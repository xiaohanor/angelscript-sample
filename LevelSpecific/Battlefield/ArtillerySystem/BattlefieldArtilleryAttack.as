class ABattlefieldArtilleryAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ExplosionComp;
	default ExplosionComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent Decal;

	UPROPERTY()
	float TargetScale = 6;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//Replace with object pooling logic
		Timer::SetTimer(this, n"DestroyAttack", 6.0);
		Timer::SetTimer(this, n"Explode", 2.0);
	}
	
	UFUNCTION()
	private void Explode()
	{
		ExplosionComp.Activate();
	}

	//Replace with object pooling logic
	UFUNCTION()
	void DestroyAttack()
	{
		DestroyActor();
	}
}