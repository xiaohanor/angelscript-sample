class AOilRigPiston : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PistonRoot;

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	USceneComponent SmashRoot;

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	UBoxComponent KillTrigger1;
	default KillTrigger1.RelativeLocation = FVector(0.0, 0.0, -2000.0);
	default KillTrigger1.BoxExtent = FVector(150.0, 390.0, 100.0);

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	UBoxComponent KillTrigger2;
	default KillTrigger2.RelativeLocation = FVector(0.0, 0.0, -2000.0);
	default KillTrigger2.BoxExtent = FVector(150.0, 390.0, 100.0);

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	UBoxComponent KillTrigger3;
	default KillTrigger3.RelativeLocation = FVector(0.0, 0.0, -2000.0);
	default KillTrigger3.BoxExtent = FVector(150.0, 390.0, 100.0);

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	UBoxComponent KillTrigger4;
	default KillTrigger4.RelativeLocation = FVector(0.0, 0.0, -2000.0);
	default KillTrigger4.BoxExtent = FVector(150.0, 390.0, 100.0);

	UPROPERTY(DefaultComponent, Attach = SmashRoot)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditDefaultsOnly)
	float SmashDistance = 1000.0;

	UPROPERTY(EditDefaultsOnly)
	float SmashDuration = 1.5;
	UPROPERTY(EditDefaultsOnly)
	float SmashInterval = 4.5;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SmashCurve;

	UPROPERTY(EditAnywhere)
	float SmashDelay = 0.0;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	bool bSmashTriggered = false;
	bool bHitTop = false;
	bool bMovingUp = false;
	bool bMovingDown = false;

	float PreviousValue = 0.0;
	float PreviousWrappedTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<UBoxComponent> Boxes = GetComponentsByClass(UBoxComponent);
		for (UBoxComponent Box : Boxes)
		{
			Box.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		}
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!bMovingDown)
			return;

		Player.KillPlayer(FPlayerDeathDamageParams(), DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float CurTime = Time::PredictedGlobalCrumbTrailTime - SmashDelay;
		float WrappedTime = Math::Wrap(CurTime, 0.0, SmashDuration + SmashInterval);
		float CurValue = SmashCurve.GetFloatValue(Math::Saturate(WrappedTime / SmashDuration));

		float Dist = Math::Lerp(0.0, SmashDistance, CurValue);
		PistonRoot.SetRelativeLocation(FVector(0.0, 0.0, -Dist));

		// Detect when we've smashed the bottom
		if (CurValue >= 1.0 && !bSmashTriggered)
		{
			bSmashTriggered = true;
			UOilRigPistonEventHandler::Trigger_HitConstraintDown(this);
			BP_HitBottom();

			CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		}
		else if (CurValue < 1.0)
		{
			bSmashTriggered = false;
		}

		// Detect when we've hit the top
		if (CurValue <= 0.0 && !bHitTop)
		{
			bHitTop = true;
			UOilRigPistonEventHandler::Trigger_HitTopPosition(this);
		}
		else if (CurValue > 0.0)
		{
			bHitTop = false;
		}

		// Detect when we start moving up or down
		if (CurValue > PreviousValue)
		{
			if (!bMovingDown)
				UOilRigPistonEventHandler::Trigger_StartMovingDown(this);
			
			bMovingDown = true;
			bMovingUp = false;
		}
		else if (CurValue < PreviousValue)
		{
			if (!bMovingUp)
				UOilRigPistonEventHandler::Trigger_StartMovingUp(this);
			
			bMovingUp = true;
			bMovingDown = false;
		}

		// Detect when we restart the whole sequence
		if (WrappedTime < PreviousWrappedTime)
		{
			UOilRigPistonEventHandler::Trigger_SmashSequenceStarted(this);
		}

		PreviousValue = CurValue;
		PreviousWrappedTime = WrappedTime;
	}

	UFUNCTION(BlueprintEvent)
	void BP_HitBottom() {}
}

class UOilRigPistonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartMovingDown() {}
	UFUNCTION(BlueprintEvent)
	void StartMovingUp() {}
	UFUNCTION(BlueprintEvent)
	void HitConstraintDown() {}
	UFUNCTION(BlueprintEvent)
	void SmashSequenceStarted() {}
	UFUNCTION(BlueprintEvent)
	void HitTopPosition() {}
}