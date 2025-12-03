class ASkylineBuildingDragBoxLock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LockMesh;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComponent;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Timelike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleOnHit");
	}

	UFUNCTION()
	private void HandleOnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		InterfaceComponent.TriggerActivate();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, LockMesh.GetWorldLocation());
		DestroyActor();
	}
};