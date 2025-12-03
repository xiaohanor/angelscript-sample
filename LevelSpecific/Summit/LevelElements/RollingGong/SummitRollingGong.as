event void ESummitRollingGongHitEvent();

class ASummitRollingGong : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent GongRotateRoot;

	UPROPERTY(DefaultComponent, Attach = GongRotateRoot)
	UStaticMeshComponent GongMeshComp;

	UPROPERTY(DefaultComponent, Attach = GongMeshComp)
	UTeenDragonTailAttackResponseComponent RollResponseComp;
	default RollResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent, Attach = GongMeshComp)
	UTeenDragonRollAutoAimComponent RollAutoAimComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GongRotateBackSpeed = 14.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GongRotateDampening = 0.3;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GongImpulseSize = 200.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> GongHitCameraShake;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect GongHitForceFeedBack;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	bool bDebugToggleOnLoop = false;

	ESummitRollingGongHitEvent OnGongHit;

	FHazeAcceleratedRotator AccGongRotation;

	FRotator StartGongRotation;

	FTimerHandle ToggleLoopTimer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RollResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		StartGongRotation = GongRotateRoot.RelativeRotation;
		AccGongRotation.SnapTo(StartGongRotation);

		if(bDebugToggleOnLoop)
			ToggleLoopTimer = Timer::SetTimer(this, n"TriggerLoop", 3.0, true);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(ToggleLoopTimer.IsValid())
		{
			if(!bDebugToggleOnLoop)
				ToggleLoopTimer.ClearTimerAndInvalidateHandle();
			else if(!ToggleLoopTimer.IsTimerActive())
				ToggleLoopTimer = Timer::SetTimer(this, n"TriggerLoop", 3.0, true);
		}
	}

	UFUNCTION()
	private void TriggerLoop()
	{
		OnGongHit.Broadcast();
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		FVector FlatHitLocation = Params.HitLocation.ConstrainToPlane(GongMeshComp.RightVector);
		FVector FlatPlayerLocation = Params.PlayerInstigator.ActorCenterLocation.ConstrainToPlane(GongMeshComp.RightVector);
		FVector DirToImpact = (FlatPlayerLocation - FlatHitLocation).GetSafeNormal();

		TEMPORAL_LOG(this)
			.DirectionalArrow("Flat Dir to Hit", Params.HitLocation, DirToImpact * 500, 20, 400, FLinearColor::LucBlue);
		;

		float ForwardDotImpactDir = GongMeshComp.ForwardVector.DotProduct(DirToImpact);
		if(ForwardDotImpactDir < 0.4
		&& ForwardDotImpactDir > -0.4)
			return;

		bool bHitForwards = ForwardDotImpactDir > 0.0;

		float GongImpulse = GongImpulseSize;
		if(bHitForwards)
			GongImpulse *= -1;
		AccGongRotation.Velocity += FRotator(GongImpulse, 0.0, 0.0);

		Params.PlayerInstigator.PlayCameraShake(GongHitCameraShake, this, 1.0 , ECameraShakePlaySpace::World);
		Params.PlayerInstigator.PlayForceFeedback(GongHitForceFeedBack, false, true, this);

		FSummitRollingGongOnHitByRollParams EventParams;
		EventParams.GongMeshRoot = GongMeshComp;
		USummitRollingGongEventHandler::Trigger_OnHitByRoll(this, EventParams);
		OnGongHit.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccGongRotation.SpringTo(StartGongRotation, GongRotateBackSpeed, GongRotateDampening, DeltaSeconds);
		GongRotateRoot.RelativeRotation = AccGongRotation.Value;
	}
};