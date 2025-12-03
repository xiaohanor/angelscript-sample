struct FSkylineAllyChargableCarChargeProgress
{
	UPROPERTY()
	float ProgressAlpha = 0.0;
}

UCLASS(Abstract)
class USkylineAllyChargableCarEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartChargeUp(FSkylineAllyChargableCarChargeProgress Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopChargeUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedChargeUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCarCrashed() {}
}

event void FSkylineAllyCarCrashSignature();
class ASkylineAllyChargableCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UFauxPhysicsConeRotateComponent CarPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SignPivotComp;

	UPROPERTY(DefaultComponent, Attach = CarPivotComp)
	UStaticMeshComponent ChargeVisualizerMeshComp;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UFauxPhysicsForceComponent FauxPhysicsForceComponent;
	
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditInstanceOnly)
	ASkylinePowerPlugSocket Socket;

	UPROPERTY(EditInstanceOnly)
	ASkylineAllyTrafficJamCar SideCrashingCar;

	UPROPERTY()
	FSkylineAllyCarCrashSignature OnCarCrash;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike ChargeUpTimeLike;
	default ChargeUpTimeLike.Duration = 3.0;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike PedalToTheMetalTimeLike;
	default ChargeUpTimeLike.Duration = 2.0;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike CrashSignTimeLike;

	bool bCharged = false;

	bool bCrashed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FauxPhysicsTranslateComponent.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");
		ChargeUpTimeLike.BindUpdate(this, n"ChargeUpTimeLikeUpdate");
		ChargeUpTimeLike.BindFinished(this, n"ChargeUpTimeLikeFinished");
		PedalToTheMetalTimeLike.BindUpdate(this, n"PedalToTheMetalTimeLikeUpdate");
		CrashSignTimeLike.BindUpdate(this, n"CrashSignTimeLikeUpdate");
		SideCrashingCar.OnStoppedBreaking.AddUFunction(this, n"SideCrash");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		ChargeUpTimeLike.PlayWithAcceleration(0.5);

		FSkylineAllyChargableCarChargeProgress Params;
		Params.ProgressAlpha = ChargeUpTimeLike.Value;

		USkylineAllyChargableCarEventHandler::Trigger_OnStartChargeUp(this, Params);
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		ChargeUpTimeLike.StopWithDeceleration(0.5);

		USkylineAllyChargableCarEventHandler::Trigger_OnStopChargeUp(this);
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge != EFauxPhysicsTranslateConstraintEdge::AxisX_Max || bCrashed)
			return;

		bCrashed = true;
		PedalToTheMetalTimeLike.SetPlayRate(4.0);
		PedalToTheMetalTimeLike.Reverse();
		BPCrashSign();
		CrashSignTimeLike.Play();

		USkylineAllyChargableCarEventHandler::Trigger_OnCarCrashed(this);
	}

	UFUNCTION()
	private void PedalToTheMetalTimeLikeUpdate(float CurrentValue)
	{
		FauxPhysicsForceComponent.Force = FVector(Math::Lerp(0.0, 6000.0, CurrentValue), 0.0, 0.0);
	}

	UFUNCTION()
	private void ChargeUpTimeLikeUpdate(float CurrentValue)
	{
		ChargeVisualizerMeshComp.SetRelativeScale3D(FVector(0.75, 0.25, Math::Lerp(0.25, 1.75, CurrentValue)));
	}

	UFUNCTION()
	private void ChargeUpTimeLikeFinished()
	{
		if (HasControl())
			NetChargeUpFinished();

		USkylineAllyChargableCarEventHandler::Trigger_OnFinishedChargeUp(this);
	}

	UFUNCTION()
	void DevActivateCar()
	{
		ChargeUpTimeLikeFinished();
	}

	UFUNCTION(NetFunction)
	void NetChargeUpFinished()
	{
		PedalToTheMetalTimeLike.Play();
		Timer::SetTimer(this, n"DetachCable", 2.0);
		bCharged = true;
		OnCarCrash.Broadcast();
	}

	UFUNCTION()
	private void CrashSignTimeLikeUpdate(float CurrentValue)
	{
		SignPivotComp.SetRelativeRotation(FRotator(Math::Lerp(0.0, 10.0, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION()
	private void DetachCable()
	{
		Socket.ForceUnplug();
	}

	UFUNCTION(BlueprintCallable)
	void DevCrashCar()
	{
		PedalToTheMetalTimeLike.Play();
		Timer::SetTimer(this, n"DetachCable", 2.5);
		bCharged = true;
		OnCarCrash.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	private void BPCrashSign()
	{
	}

	UFUNCTION()
	void SideCrash()
	{
		CarPivotComp.ApplyImpulse(CarPivotComp.WorldLocation + FVector::UpVector * 100.0, ActorRightVector * 30.0);
	}
};