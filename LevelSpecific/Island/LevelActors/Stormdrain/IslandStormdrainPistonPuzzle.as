class AIslandStormdrainPistonPuzzle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = "MovingRoot")
	UStaticMeshComponent PistonMesh;
	default PistonMesh.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;
	
	UPROPERTY(DefaultComponent)
	UNiagaraComponent SlamVFX;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditInstanceOnly)
	FRuntimeFloatCurve MovementCurve;

	UPROPERTY(EditAnywhere)
	float Duration;

	UPROPERTY(EditInstanceOnly)
	float MaxPistonHeight = -600;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel RedPanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel BluePanelRef;

	const float ImpactTime = 0.33;
	const float MovedUpTime = 1.0;

	bool bMovingDown = false;

	float CurvePosition = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"OnStartMovingDown");
		ActionQueue.Duration(Duration, this, n"Move");

		TArray<UBoxComponent> Boxes = GetComponentsByClass(UBoxComponent);
		for (UBoxComponent Box : Boxes)
		{
			Box.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		}
	}

	UFUNCTION()
	private void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                          const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!bMovingDown)
			return;
		
		FPlayerDeathDamageParams DeathParams;
		DeathParams.bApplyStaticCamera = true;
		DeathParams.ImpactDirection = -FVector::UpVector;
		Player.KillPlayer(DeathParams, DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION()
	private void Move(float Alpha)
	{
		float PreviousCurvePosition = CurvePosition;
		CurvePosition = Alpha * Duration;
		if(PreviousCurvePosition < MovedUpTime && CurvePosition >= MovedUpTime)
		{
			OnHitUpperConstraint();
		}

		if(PreviousCurvePosition < ImpactTime && CurvePosition >= ImpactTime)
		{
			OnSlam();
		}

		float CurveValue = MovementCurve.GetFloatValue(CurvePosition);

		FVector Location = FVector(0, 0, CurveValue * MaxPistonHeight);
		MovingRoot.SetRelativeLocation(Location);
	}

	UFUNCTION()
	private void OnStartMovingDown()
	{
		bMovingDown = true;
		UIslandStormdrainPistonPuzzleEffectHandler::Trigger_OnPistonStartMovingDown(this);
	}

	UFUNCTION()
	private void OnSlam()
	{
		bMovingDown = false;
		UIslandStormdrainPistonPuzzleEffectHandler::Trigger_OnPistonHitConstraintDown(this);
		BP_OnSlam();
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		UIslandStormdrainPistonPuzzleEffectHandler::Trigger_OnPistonStartMovingUp(this);
	}

	UFUNCTION()
	private void OnHitUpperConstraint()
	{
		UIslandStormdrainPistonPuzzleEffectHandler::Trigger_OnPistonHitConstraintUp(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnSlam(){}
}


UCLASS(Abstract)
class UIslandStormdrainPistonPuzzleEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPistonStartMovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPistonHitConstraintDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPistonStartMovingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPistonHitConstraintUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStop() {}
}