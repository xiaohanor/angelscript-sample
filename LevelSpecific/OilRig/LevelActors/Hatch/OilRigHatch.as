class UOilRigHatchEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnHatchActivated() {};

	UFUNCTION(BlueprintEvent)
	void OnHatchDeactivated() {};

	UFUNCTION(BlueprintEvent)
	void OnStartShaking() {};
}

UCLASS(Abstract)
class AOilRigHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent HatchRoot;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent, Attach = HatchRoot)
	USceneComponent ShakeRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ImpactCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactFF;

	bool bActive = false;
	bool bShaking = false;
	float ShakeTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HatchRoot.OnMinConstraintHit.AddUFunction(this, n"MinConstraintHit");
		HatchRoot.OnMaxConstraintHit.AddUFunction(this, n"MaxConstraintHit");

		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"Activate");
		ActionQueue.Idle(1.8);
		ActionQueue.Event(this, n"StartShake");
		ActionQueue.Idle(1.2);
		ActionQueue.Event(this, n"Deactivate");
		ActionQueue.Idle(2.5);
	}

	UFUNCTION()
	private void MinConstraintHit(float Strength)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ImpactCamShake, this, ActorLocation, 1500.0, 2000.0, 1.0, 0.75);

		ForceFeedback::PlayWorldForceFeedback(ImpactFF, ActorLocation, true, this, 1500.0, 500.0);
	}

	UFUNCTION()
	private void MaxConstraintHit(float Strength)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ImpactCamShake, this, ActorLocation, 1500.0, 2000.0, 1.0, 0.5);

		ForceFeedback::PlayWorldForceFeedback(ImpactFF, ActorLocation, true, this, 1500.0, 500.0);
	}

	UFUNCTION(NotBlueprintCallable)
	void Activate()
	{
		bActive = true;
		BP_Activate();

		UOilRigHatchEventHandler::Trigger_OnHatchActivated(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}

	UFUNCTION(NotBlueprintCallable)
	void StartShake()
	{
		ShakeTime = 0.0;
		bShaking = true;
		UOilRigHatchEventHandler::Trigger_OnStartShaking(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void Deactivate()
	{
		bActive = false;
		bShaking = false;
		BP_Deactivate();

		UOilRigHatchEventHandler::Trigger_OnHatchDeactivated(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime);

		if (bActive)
			HatchRoot.ApplyAngularForce(-20.0);

		if (bShaking)
		{
			ShakeTime += DeltaTime;
			float SineRotate = Math::Sin(ShakeTime * 30.0);
			ShakeRoot.SetRelativeRotation(FRotator(0.0, 0.0, 0.3) * SineRotate);
		}
	}
}