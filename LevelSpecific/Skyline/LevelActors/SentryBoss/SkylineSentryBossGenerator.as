event void FOnGeneratorDestroy();

class ASkylineSentryBossGenerator : AHazeActor
{
	FOnGeneratorDestroy OnGeneratorDestroy;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent ResponseComp;

	int HitPoints = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHit.AddUFunction(this, n"OnHit");
	}

	UFUNCTION()
	private void OnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		HitPoints--;

		if(HitPoints <= 0)
			DestroyActor();

	}


	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		OnGeneratorDestroy.Broadcast();

	}

}