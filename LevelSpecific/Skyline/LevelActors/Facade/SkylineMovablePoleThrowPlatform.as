class ASkylineMovablePoleThrowPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	USkylineWhipPoleResponseComponent SkylineWhipPoleResponseComponent;

	UPROPERTY(DefaultComponent)
	UDeathOnImpactComponent DeathOnImpactComponent;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditAnywhere)
	float TravelDistance = 1000.0;

	UPROPERTY(EditAnywhere)
	float TravelDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float WaitDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float DoorOpenDuration = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Play();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Scrub the action queue to the predicted time to match in network
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION()
	private void Play()
	{
		ActionQueue.Empty();
		ActionQueue.SetLooping(true);

		ActionQueue.Duration(TravelDuration, this, n"MovementUpdate");
		ActionQueue.Event(this, n"ExtendFinished");
		ActionQueue.Idle(WaitDuration);
		ActionQueue.ReverseDuration(TravelDuration, this, n"MovementUpdate");
		ActionQueue.Event(this, n"RetractFinished");
		ActionQueue.Idle(WaitDuration);
	}

	UFUNCTION()
	private void MovementUpdate(float CurrentValue)
	{
		float Alpha = Curve::SmoothCurveZeroToOne.GetFloatValue(CurrentValue);
		PlatformRoot.SetRelativeLocation(FVector::ForwardVector * Alpha * TravelDistance);
	}

	UFUNCTION()
	private void ExtendFinished()
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		USkylineKineticSplineFollowActorEventHandler::Trigger_OnHitBottom(this);
	}

	UFUNCTION()
	private void RetractFinished()
	{
		USkylineKineticSplineFollowActorEventHandler::Trigger_OnHitTop(this);
		InterfaceComp.TriggerActivate();
		Timer::SetTimer(this, n"CloseDoor", DoorOpenDuration);
	}

	UFUNCTION()
	private void CloseDoor()
	{
		InterfaceComp.TriggerDeactivate();
	}
};