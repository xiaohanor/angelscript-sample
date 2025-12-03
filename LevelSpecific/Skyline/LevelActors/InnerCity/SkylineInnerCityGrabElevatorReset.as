event void FFirstBladeHit();

class ASkylineInnerCityGrabElevatorReset : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ClutchA;

	UPROPERTY(DefaultComponent)
	USceneComponent ClutchB;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;
	

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComponent;

	UPROPERTY()
	FFirstBladeHit OnFirstBladeHit;
	
	UPROPERTY(EditAnywhere)
	ASkylineCablePanelFront CablePanel;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	float ClutchDistance = 80.0;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleHit");
		CablePanel.OnWhipSlingableGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityBladeResponseComponent.AddResponseComponentDisable(this);
	}


	UFUNCTION()
	private void HandleGrabbed()
	{
		GravityBladeResponseComponent.RemoveResponseComponentDisable(this);
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		OnFirstBladeHit.Broadcast();
		//Timelike.Play();
		InterfaceComponent.TriggerActivate();
		HandlePointOfInterest();
		MaterialChange();

		GravityBladeResponseComponent.AddResponseComponentDisable(this);
		QueueComp.Duration(0.25, this, n"MoveDownAction");
		QueueComp.Idle(0.25);
		QueueComp.ReverseDuration(0.5, this, n"MoveUpAction");
		QueueComp.Event(this, n"EnableHit");
		
	}

	UFUNCTION()
	private void MoveDownAction(float Alpha)
	{
		ClutchA.SetRelativeLocation(FVector::UpVector * ClutchDistance * Alpha);
		ClutchB.SetRelativeLocation(FVector::UpVector * -ClutchDistance * Alpha);
	}

	UFUNCTION()
	private void MoveUpAction(float Alpha)
	{
		ClutchA.SetRelativeLocation(FVector::UpVector * ClutchDistance * Alpha);
		ClutchB.SetRelativeLocation(FVector::UpVector * -ClutchDistance * Alpha);
	}

	UFUNCTION()
	private void EnableHit()
	{
		GravityBladeResponseComponent.RemoveResponseComponentDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		/*if(!Timelike.IsPlaying()){
			Timelike.Reverse();
			MaterialChangeBack();
		}*/
	}

	UFUNCTION(BlueprintEvent)
	void HandlePointOfInterest(){}

	UFUNCTION(BlueprintEvent)
	void MaterialChangeBack(){}

	UFUNCTION(BlueprintEvent)
	void MaterialChange(){}
};