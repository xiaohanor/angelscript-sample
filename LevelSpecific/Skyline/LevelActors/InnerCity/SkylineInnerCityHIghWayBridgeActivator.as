UCLASS(Abstract)
class USkylineInnerCityHIghWayBridgeActivatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPulseArrived() {}


};
class ASkylineInnerCityHIghWayBridgeActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SparkVFXComp;
	
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ActorWithSpline;
	UHazeSplineComponent SplineComp;


	UPROPERTY(DefaultComponent)
	USceneComponent RotatorA;

	UPROPERTY(DefaultComponent)
	USceneComponent RotatorB;

	UPROPERTY()
	FSkylineElectricBoxActivatedSignature OnBoxHit;

	UPROPERTY(EditInstanceOnly)
	ASkylineGravityPanel GravityPanel;

	UPROPERTY(EditAnywhere)
	float PulseSpeed = 1000.0;
	UPROPERTY(EditAnywhere)
	bool bSlowdownToSyncActivationInNetwork = true;

	UPROPERTY()
	float ActivationDuration = 1.0;

	float ProgressAlongCable = 0.0;
	float NetworkSlowdown = 1.0;
	FHazeAcceleratedFloat RotationSpeed;
	float BaseRotationSpeed = 90.0;
	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleOnHit");
		GravityPanel.OnGravityShifted.AddUFunction(this, n"HandleOnGravityShifted");
		GravityBladeResponseComponent.AddResponseComponentDisable(this);
		SetActorTickEnabled(false);
		RotationSpeed.SnapTo(BaseRotationSpeed);
		SplineComp = UHazeSplineComponent::Get(ActorWithSpline);
		if (!IsValid(SplineComp))
			PrintToScreen("Actor has no spline!!!", 10.0, FLinearColor::Red);
	}

	UFUNCTION()
	private void HandleOnGravityShifted()
	{
		GravityBladeResponseComponent.RemoveResponseComponentDisable(this, true);
	}

	UFUNCTION()
	private void HandleOnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(!bDoOnce)
			return;

		bDoOnce = false;
		ProgressAlongCable = 0.0;
		SparkVFXComp.SetHiddenInGame(false);
		SparkVFXComp.Activate();
		SetActorTickEnabled(true);
		BPActivated();
		RotationSpeed.SnapTo(BaseRotationSpeed * 20.0);
		GravityBladeResponseComponent.AddResponseComponentDisable(this);
		GravityBladeTargetComponent.Disable(this);
		GravityBladeTargetComponent.AddWidgetBlocker(this);
		GravityBladeTargetComponent.AddComponentVisualsBlocker(this);
		GravityBladeTargetComponent.DestroyComponent(this);
		GravityBladeOutlineComponent.DestroyComponent(this);
		USkylineBrokenElectricBoxEventHandler::Trigger_OnHit(this);

		if (Network::IsGameNetworked() && Game::Mio.HasControl() && bSlowdownToSyncActivationInNetwork)
		{
			float NormalTime = SplineComp.SplineLength / PulseSpeed;
			float SlowedDownTime = NormalTime + Time::GetEstimatedCrumbRoundtripDelay();
			NetworkSlowdown = (NormalTime / SlowedDownTime);
		}
		else
		{
			NetworkSlowdown = 1.0;
		}

		GravityBladeResponseComponent.AddResponseComponentDisable(this);
		OnBoxHit.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BPActivated()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BPDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ProgressAlongCable += DeltaSeconds * PulseSpeed * NetworkSlowdown;

		if (ProgressAlongCable >= SplineComp.SplineLength)
		{
			OnPulseArrive();

			return;
		}

		RotatorA.AddLocalRotation(FRotator(0.0, RotationSpeed.Value * DeltaSeconds, 0.0));
		RotatorB.AddLocalRotation(FRotator(0.0, -RotationSpeed.Value * DeltaSeconds, 0.0));

		FVector NewPulseWorldLocation = SplineComp.GetWorldLocationAtSplineDistance(ProgressAlongCable);

		SparkVFXComp.SetWorldLocation(NewPulseWorldLocation);
	}

	UFUNCTION()
	private void OnPulseArrive()
	{
		SparkVFXComp.Deactivate();
		SparkVFXComp.SetHiddenInGame(true);
		SetActorTickEnabled(false);
		InterfaceComp.TriggerActivate();
		BPDeactivated();
		Timer::SetTimer(this, n"PulseFinished", ActivationDuration);

		GravityBladeResponseComponent.RemoveResponseComponentDisable(this);

		USkylineBrokenElectricBoxEventHandler::Trigger_OnPulseArrived(this);
	}

	UFUNCTION()
	private void PulseFinished()
	{
		InterfaceComp.TriggerDeactivate();
	}

};