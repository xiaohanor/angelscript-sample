enum ESkylineMagnetCraneLocationIndex
{
	Left,
	Center,
	Right
}


class ASkylineMagnetCrane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.MinX = 0.0;
	default TranslateComp.MaxX = 0.0;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.MinY = 0.0;
	default TranslateComp.MaxY = 0.0;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinZ = -800.0;
	default TranslateComp.MaxZ = 0.0;
	default TranslateComp.ConstrainBounce = 0.25;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent GravityForce;
	default GravityForce.Force = FVector::UpVector * -5000.0;
	default GravityForce.bWorldSpace = false;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent MagnetForce;
	default MagnetForce.Force = FVector::UpVector * 10000.0;
	default MagnetForce.bWorldSpace = false;

	UPROPERTY(EditDefaultsOnly)
	USphereComponent BladeCollision;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent BladeTargetComp;

	UPROPERTY(DefaultComponent, Attach = BladeTargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent DeathVolume;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeResponseComp;
	default BladeResponseComp.InteractionType = EGravityBladeCombatInteractionType::HorizontalRight;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
    UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponentGround;

    UPROPERTY(DefaultComponent)
    UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponentReAttach;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ContainerHolder;
	FVector InitialRelativeLocation;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ClutchRoot;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(DefaultComponent, Attach = ClutchRoot)
	USceneComponent ClutchA;

	UPROPERTY(DefaultComponent, Attach = ClutchRoot)
	USceneComponent ClutchB;

	UPROPERTY(EditDefaultsOnly)
	TArray<USceneComponent> Claws;

	float ClutchDistance = 60.0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ClawAnimation;
	default ClawAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ClawAnimation.Curve.AddDefaultKey(0.0, 1.0);
	default ClawAnimation.bCurveUseNormalizedTime = true;
	default ClawAnimation.Duration = 1.0;

	UPROPERTY(EditAnywhere)
	float DeactiveDuration = 4.0;

	UPROPERTY(EditAnywhere)
	float ClawOpenAngle = 30.0;

	UPROPERTY(EditAnywhere)
	float ContainerHolderDistance = 130.0;

	UPROPERTY(EditInstanceOnly)
	ESkylineMagnetCraneLocationIndex CraneLocationIndex = ESkylineMagnetCraneLocationIndex::Left;


	bool bIsActive = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstraintHit");
		BladeResponseComp.OnHit.AddUFunction(this, n"HandleHit");
		DeathVolume.OnComponentBeginOverlap.AddUFunction(this, n"HandleDeathVolumeOverlap");
		ClawAnimation.BindUpdate(this, n"ClawAnimationUpdate");
		ClawAnimation.BindFinished(this, n"ClawAnimationFinished");

		InitialRelativeLocation = ContainerHolder.RelativeLocation;
	}

UFUNCTION()
    private void HandleConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
    {
        if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max)
        {
            USkylineMagnetCraneEventHandler::Trigger_OnReturnFinished(this);
            CameraShakeForceFeedbackComponentReAttach.ActivateCameraShakeAndForceFeedback();
            ClawAnimation.Reverse();
        }
        if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min)
        {
            CameraShakeForceFeedbackComponentGround.ActivateCameraShakeAndForceFeedback();
            USkylineMagnetCraneEventHandler::Trigger_OnHitGround(this);
        }
    }

	UFUNCTION()
	private void ClawAnimationUpdate(float CurrentValue)
	{
		for (auto Claw : Claws)
		{
			FRotator RelativeRotation = Claw.RelativeRotation;
			RelativeRotation.Roll = -CurrentValue * ClawOpenAngle;
			Claw.RelativeRotation = RelativeRotation;
		}

		FVector Offset = -FVector::UpVector * ContainerHolderDistance * CurrentValue;
		ContainerHolder.RelativeLocation = InitialRelativeLocation + Offset; 
	}

	UFUNCTION()
	private void ClawAnimationFinished()
	{		
		if (ClawAnimation.IsReversed())
			USkylineMagnetCraneEventHandler::Trigger_OnClawsFinished(this);
	}

	UFUNCTION()
	private void HandleDeathVolumeOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr || Player.IsMio())
			return;

		Player.KillPlayer(DeathEffect = DeathEffect);
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (!bIsActive)
			return;

		Deactivate();
		Timer::SetTimer(this, n"Activate", DeactiveDuration);
		FSkylineMagnetCraneLockImpactParams Params;
		Params.Crane = this;
		USkylineMagnetCraneEventHandler::Trigger_OnLockImpact(this, Params);

		QueueComp.Event(this, n"BladeHitAction");
		QueueComp.Duration(0.25, this, n"MoveDownAction");
		QueueComp.Idle(1.0);
		QueueComp.ReverseDuration(DeactiveDuration - 1.0 - 0.25, this, n"MoveUpAction");
		QueueComp.Event(this, n"ReconnectedAction");
	}

	UFUNCTION()
	private void BladeHitAction()
	{
	}

	UFUNCTION()
	private void MoveDownAction(float Alpha)
	{
		ClutchA.SetRelativeLocation(FVector::UpVector * ClutchDistance * Alpha);
		ClutchB.SetRelativeLocation(FVector::UpVector * -ClutchDistance * Alpha);
	}

	UFUNCTION()
	private void MoveUpAction(float Alpha)
	{
		ClutchA.SetRelativeLocation(FVector::UpVector * ClutchDistance * Alpha);
		ClutchB.SetRelativeLocation(FVector::UpVector * -ClutchDistance * Alpha);
	}

	UFUNCTION()
	private void ReconnectedAction()
	{
	}

	UFUNCTION()
	void Activate()
	{
		bIsActive = true;		
		MagnetForce.RemoveDisabler(this);
		BladeTargetComp.Enable(this);
		BP_OnActivate();

		USkylineMagnetCraneEventHandler::Trigger_OnStartReturn(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActive = false;
		MagnetForce.AddDisabler(this);
		ClawAnimation.Play();
		BladeTargetComp.Disable(this);
		BP_OnDeactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivate() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivate() {}
};