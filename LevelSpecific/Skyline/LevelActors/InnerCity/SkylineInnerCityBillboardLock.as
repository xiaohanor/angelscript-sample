class ASkylineInnerCityBillboardLock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LockMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot1;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot2;

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
		Timelike.BindUpdate(this, n"HandleAnimationUpdate1");
		
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
	}



	UFUNCTION()
	private void HandleAnimationUpdate1(float CurrentValue)
	{
		Pivot1.RelativeRotation = FRotator(0.0, CurrentValue * -45, 0.0);
		Pivot2.RelativeRotation = FRotator(0.0, CurrentValue * 45, 0.0);
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		GravityBladeTargetComponent.DestroyComponent(this);
		Timelike.Play();
	
		InterfaceComponent.TriggerActivate();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, LockMesh.GetWorldLocation());
		HandleMaterialChange();
	}

	UFUNCTION(BlueprintEvent)
	void HandleMaterialChange()
	{
		
	}
};