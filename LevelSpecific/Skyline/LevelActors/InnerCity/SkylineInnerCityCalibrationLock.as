class ASkylineInnerCityCalibrationLock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LockPivot;

	UPROPERTY(DefaultComponent, Attach = LockPivot)
	UStaticMeshComponent LockMesh;

	UPROPERTY()
	FHazeTimeLike Timelike;

	UPROPERTY(DefaultComponent)
	USceneComponent SceneComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComponent;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem SparkVFX;

	UPROPERTY()
	bool bIsLocked = false;
	float SpinValue = 1.0;

	UPROPERTY(EditAnywhere)
	ASkylineInnerCityCalibrationMeter CalibrationMeter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
		Timelike.BindUpdate(this, n"HandleTimeLikeUpdate");
		InterfaceComponent.OnActivated.AddUFunction(this, n"HandleOnActivated");
		
	}
	


	UFUNCTION()
	private void HandleOnActivated(AActor Caller)
	{
		BP_HandleActivated();
	}

	UFUNCTION()
	private void HandleTimeLikeUpdate(float CurrentValue)
	{
		LockPivot.RelativeRotation = (FRotator(0.0, 360.0 * SpinValue * CurrentValue, 0.0));
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		Timelike.PlayFromStart();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkVFX, SceneComp.GetWorldLocation());
		BP_HandleMaterialChange();

		if(bIsLocked)
		{
			InterfaceComponent.TriggerDeactivate();
			bIsLocked=false;
			SpinValue = -1.0;
		}else{
			SpinValue = 1.0;
			InterfaceComponent.TriggerActivate();	
			bIsLocked=true;	
			if(CalibrationMeter.bIsCorrectValue)
				{
					GravityBladeTargetComponent.DisableForPlayer(Game::Mio, this);
					GravityBladeResponseComponent.AddResponseComponentDisable(this);
					CalibrationMeter.TargetComp.DisableForPlayer(Game::Zoe, this);
				}
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleMaterialChange()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleActivated()
	{
	}
};