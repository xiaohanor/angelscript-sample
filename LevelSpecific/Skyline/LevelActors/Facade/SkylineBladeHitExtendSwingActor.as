class ASkylineBladeHitExtendSwingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UGravityBladeCombatTargetComponent BladeTargetComp;

	UPROPERTY(DefaultComponent, Attach = BladeTargetComp)
	UTargetableOutlineComponent TargetOutlineComp;

	UPROPERTY(DefaultComponent, Attach = BladeTargetComp)
	USphereComponent BladeCollisionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = GrapplingPointPivot)
	USwingPointComponent SwingPointComp;
	default SwingPointComp.bStartDisabled = true;
	
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeResponseComp;

	UPROPERTY(DefaultComponent)
	USceneComponent CogRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent GrapplingPointPivot;

	UPROPERTY(DefaultComponent, Attach = CogRoot)
	USceneComponent CogRotatingPivot;

	UPROPERTY(DefaultComponent)
	USceneComponent CogRootB;

	UPROPERTY(DefaultComponent, Attach = CogRootB)
	USceneComponent CogRotatingPivotB;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike GrappleTimeLike;

	float CogRadius = 50.0; // 150.0
	float RotationAngle = 0.0;
	float TraslationDistance = 0.0;

	UPROPERTY()
	float OutForce = 1000.0;

	UPROPERTY()
	float InForce = 1000.0;

	UPROPERTY()
	float Duration = 3.0;

	bool bIsRetracting = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeResponseComp.OnHit.AddUFunction(this, n"HandleBladeHit");
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstraintHit");
		GrappleTimeLike.BindUpdate(this, n"HandleTimelikeUpdate");
		SwingPointComp.Disable(this);

		TraslationDistance = Math::Abs(TranslateComp.MaxX - TranslateComp.MinX);
		RotationAngle = (TraslationDistance / (2 * PI * CogRadius)) * 360.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = Math::NormalizeToRange(TranslateComp.RelativeLocation.X, TranslateComp.MinX, TranslateComp.MaxX);
		CogRotatingPivot.RelativeRotation = FRotator(0.0, 0.0, Alpha * RotationAngle);
		CogRotatingPivotB.RelativeRotation = FRotator(0.0, 0.0, Alpha * RotationAngle);

		float FFFrequency = 30.0;
		float FFIntensity = 0.4;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;

		if(bIsRetracting)
			ForceFeedback::PlayWorldForceFeedbackForFrame(FF, ActorLocation, 300, 400, 1.0, EHazeSelectPlayer::Both);
	}

	UFUNCTION()
	private void HandleConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Max)
		{
			SwingPointComp.Enable(this);
			GrappleTimeLike.Play();
			bIsRetracting = true;
		}

		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Min)
		{
			SwingPointComp.Disable(this);
			GrappleTimeLike.Reverse();
			bIsRetracting = false;
			//BladeResponseComp.RemoveResponseComponentDisable(this);
			BP_Deactivate();
		}
	}

	UFUNCTION()
	private void HandleTimelikeUpdate(float CurrentValue)
	{
		GrapplingPointPivot.SetRelativeRotation(FRotator(0.0, 0.0, 180 * CurrentValue));
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		ForceComp.Force = FVector::ForwardVector * OutForce;

		BP_Activate();

		Timer::SetTimer(this, n"Retract", Duration);
		
		//BladeResponseComp.AddResponseComponentDisable(this);
	}

	UFUNCTION()
	private void Retract()
	{
		ForceComp.Force = FVector::BackwardVector * InForce;
		UBP_SkylineBladeHitExtendSwingActorEventHandler::Trigger_OnRetract(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Deactivate()
	{
	}
};