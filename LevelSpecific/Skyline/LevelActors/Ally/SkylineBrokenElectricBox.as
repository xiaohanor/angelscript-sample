event void FSkylineElectricBoxActivatedSignature();

UCLASS(Abstract)
class USkylineBrokenElectricBoxEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPulseArrived() {}
}

class ASkylineBrokenElectricBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root; 

	UPROPERTY(DefaultComponent)
	USceneComponent RotatorA;

	UPROPERTY(DefaultComponent)
	USceneComponent RotatorB;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SparkVFXComp;
	
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent GravityBladeResponseComponent;
	default GravityBladeResponseComponent.InteractionType = EGravityBladeCombatInteractionType::HorizontalRight;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ActorWithSpline;
	UPROPERTY()
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	FSkylineElectricBoxActivatedSignature OnBoxHit;

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

	bool bActivePulse = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleOnHit");

//		SetActorTickEnabled(false);

		SplineComp = UHazeSplineComponent::Get(ActorWithSpline);
		if (!IsValid(SplineComp))
			PrintToScreen("Actor has no spline!!!", 10.0, FLinearColor::Red);
	
		RotationSpeed.SnapTo(BaseRotationSpeed);
	}

	UFUNCTION()
	private void HandleOnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		RotationSpeed.SnapTo(BaseRotationSpeed * 20.0);

		ProgressAlongCable = 0.0;
		SparkVFXComp.SetHiddenInGame(false);
		SparkVFXComp.Activate();

		bActivePulse = true;
//		SetActorTickEnabled(true);
		BPActivated();
		
		GravityBladeResponseComponent.AddResponseComponentDisable(this);

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
		RotatorA.AddLocalRotation(FRotator(0.0, RotationSpeed.Value * DeltaSeconds, 0.0));
		RotatorB.AddLocalRotation(FRotator(0.0, -RotationSpeed.Value * DeltaSeconds, 0.0));

		RotationSpeed.AccelerateTo(BaseRotationSpeed, 2.0, DeltaSeconds);

		ProgressAlongCable += DeltaSeconds * PulseSpeed * NetworkSlowdown;

		if (bActivePulse && ProgressAlongCable >= SplineComp.SplineLength)
		{
			OnPulseArrive();

			return;
		}

		FVector NewPulseWorldLocation = SplineComp.GetWorldLocationAtSplineDistance(ProgressAlongCable);

		SparkVFXComp.SetWorldLocation(NewPulseWorldLocation);
	}

	UFUNCTION()
	private void OnPulseArrive()
	{
		SparkVFXComp.Deactivate();
		SparkVFXComp.SetHiddenInGame(true);
//		SetActorTickEnabled(false);
		InterfaceComp.TriggerActivate();
		BPDeactivated();
		Timer::SetTimer(this, n"PulseFinished", ActivationDuration);

		GravityBladeResponseComponent.RemoveResponseComponentDisable(this);

		USkylineBrokenElectricBoxEventHandler::Trigger_OnPulseArrived(this);
	
		bActivePulse = false;
	}

	UFUNCTION()
	private void PulseFinished()
	{
		InterfaceComp.TriggerDeactivate();
	}
};