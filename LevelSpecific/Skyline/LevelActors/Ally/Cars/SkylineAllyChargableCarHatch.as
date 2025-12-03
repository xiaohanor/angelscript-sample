struct FSkylineAllyChargableCarHatchProgress
{
	UPROPERTY()
	float ProgressAlpha = 0.0;
}

UCLASS(Abstract)
class USkylineAllyChargableCarHatchEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchBeginOpen(FSkylineAllyChargableCarHatchProgress Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchBeginClose() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchFinishedClose() {}
}

class ASkylineAllyChargableCarHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HatchPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(EditInstanceOnly)
	ASkylineAllyChargableCar Car;

	UPROPERTY(EditInstanceOnly)
	ASkylinePowerPlugSocket Socket;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike ChargeHatchTimeLike;

	UPROPERTY()
	float OpenDuration = 2.0;

	bool bHatchOpen = false;

	bool bCarCharged = false;

	float ProgressAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
		ChargeHatchTimeLike.BindUpdate(this, n"ChargeHatchTimeLikeUpdate");
		ChargeHatchTimeLike.BindFinished(this, n"ChargeHatchTimeLikeFinished");

		Car.InterfaceComp.OnActivated.AddUFunction(this, n"HandleCarActivated");
		Car.InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleCarDeactivated");

		Socket.SetActorEnableCollision(false);
		Socket.AutoAimTarget.Disable(this);
	}

	UFUNCTION()
	private void ChargeHatchTimeLikeUpdate(float CurrentValue)
	{
		HatchPivot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(0.0, -120.0, CurrentValue)));

		ProgressAlpha = CurrentValue;
	}

	UFUNCTION()
	private void ChargeHatchTimeLikeFinished()
	{
		if (!ChargeHatchTimeLike.IsReversed())
			OnHatchOpened();
		else
			OnHatchClosed();
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		GravityBladeResponseComponent.AddResponseComponentDisable(this);

		ChargeHatchTimeLike.Play();

		FSkylineAllyChargableCarHatchProgress Params;
		Params.ProgressAlpha = ProgressAlpha;

		USkylineAllyChargableCarHatchEventHandler::Trigger_OnHatchBeginOpen(this, Params);
	}

	UFUNCTION()
	private void OnHatchOpened()
	{
		Socket.SetActorEnableCollision(true);
		Socket.AutoAimTarget.Enable(this);

		Timer::SetTimer(this, n"CloseHatch", OpenDuration);
	}

	UFUNCTION()
	private void CloseHatch()
	{
		if (bCarCharged)
			return;

		Socket.SetActorEnableCollision(false);
		Socket.AutoAimTarget.Disable(this);

		ChargeHatchTimeLike.Reverse();

		USkylineAllyChargableCarHatchEventHandler::Trigger_OnHatchBeginClose(this);
	}

	UFUNCTION()
	private void OnHatchClosed()
	{
		GravityBladeResponseComponent.RemoveResponseComponentDisable(this);

		USkylineAllyChargableCarHatchEventHandler::Trigger_OnHatchFinishedClose(this);
	}

	UFUNCTION()
	private void HandleCarActivated(AActor Caller)
	{
		Timer::ClearTimer(this, n"CloseHatch");
	}

	UFUNCTION()
	private void HandleCarDeactivated(AActor Caller)
	{
		ChargeHatchTimeLike.Reverse();
	}
};