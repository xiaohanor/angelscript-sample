class ASkylineInnerCityLauncherButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent GravComTargComp;

	UPROPERTY(DefaultComponent)
	USceneComponent LockPivot;

	UPROPERTY()
	FHazeTimeLike Timelike;

	UPROPERTY(DefaultComponent, Attach = GravComTargComp)
	UTargetableOutlineComponent TargOutlineComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	ASkylineInnerCityLaunchLauncher Launcher;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent GravityBladeCombatInteractionResponseComponent;

	float SpinValue = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeComp.OnHit.AddUFunction(this, n"HandleHit");
		Timelike.BindUpdate(this, n"HandleTimeLikeUpdate");
		Timelike.BindFinished(this, n"HandleTimeLikeFinshed");
		
	}
	
	UFUNCTION()
	private void HandleTimeLikeFinshed()
	{
		GravityBladeComp.RemoveResponseComponentDisable(this, true);
	}

	UFUNCTION()
	private void HandleTimeLikeUpdate(float CurrentValue)
	{
		LockPivot.RelativeRotation = (FRotator( 0.0, 0.0, -360.0  * CurrentValue));
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		GravityBladeComp.AddResponseComponentDisable(this, true);
		InterfaceComp.TriggerActivate();
		Timelike.PlayFromStart();
		BP_HandleMaterialChange();
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleMaterialChange()
	{
	}

	

};