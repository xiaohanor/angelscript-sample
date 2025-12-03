UCLASS(Abstract)
class USkylineCrusherCoreEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchOpen()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchClose()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCoreDestroyed()
	{
	}	
};

class ASkylineCrusherCore : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityWhipSlingAutoAimComponent WhipSlingTargetComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent SlingCollision;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent HatchPivot;

	UPROPERTY(DefaultComponent, Attach = HatchPivot)
	UFauxPhysicsForceComponent CloseHatchForceComp;

	UPROPERTY(DefaultComponent, Attach = HatchPivot)
	UFauxPhysicsForceComponent OpenHatchForceComp;

	UPROPERTY(DefaultComponent, Attach = HatchPivot)
	UCapsuleComponent BladeCollison;

	UPROPERTY(DefaultComponent, Attach = BladeCollison)
	UGravityBladeCombatTargetComponent BladeCombatTargetComp;

	UPROPERTY(DefaultComponent, Attach = HatchPivot)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeCombatResponseComp;
	default BladeCombatResponseComp.InteractionType = EGravityBladeCombatInteractionType::VerticalUp;

	UPROPERTY(DefaultComponent)
    UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent WhipImpactResponseComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	float HatchOpenDuration = 2.0;
	float HatchCloseTime = 0.0;
	float HatchAngle = 150.0;
	bool bHatchOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	SlingCollision.AddComponentCollisionBlocker(this);

		WhipSlingTargetComp.Disable(this);
		OpenHatchForceComp.AddDisabler(this);

		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleBladeHit");
		WhipImpactResponseComp.OnImpact.AddUFunction(this, n"HandleWhipImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bHatchOpen && Time::GameTimeSeconds > HatchCloseTime)
			CloseHatch();

		float Alpha = Math::NormalizeToRange(Math::RadiansToDegrees(HatchPivot.CurrentRotation), HatchPivot.ConstrainAngleMin, HatchPivot.ConstrainAngleMax);

		if (!bHatchOpen && Alpha > 0.6)
			ActivateBladeTarget();

		if (WhipSlingTargetComp.IsDisabled() && Alpha <= 0.5)
			WhipSlingTargetComp.Enable(this);

		if (!WhipSlingTargetComp.IsDisabled() && Alpha > 0.5)
			WhipSlingTargetComp.Disable(this);
	}


	UFUNCTION()
	private void HandleWhipImpact(FGravityWhipImpactData ImpactData)
	{
		if (ImpactData.HitResult.Component != SlingCollision)
			return;

		SlingCollision.AddComponentCollisionBlocker(ImpactData.HitResult.Component);

		BP_OnWhipImpact(ImpactData);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	
		USkylineCrusherCoreEventHandler::Trigger_OnCoreDestroyed(this);
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (bHatchOpen)
			return;

		BP_OnBladeHit(HitData);
		OpenHatch();
	}

	void OpenHatch()
	{
	//	SlingCollision.RemoveComponentCollisionBlocker(this);

		DeactivateBladeTarget();

		bHatchOpen = true;
		CloseHatchForceComp.AddDisabler(this);
		OpenHatchForceComp.RemoveDisabler(this);
		HatchCloseTime = Time::GameTimeSeconds + HatchOpenDuration;

		USkylineCrusherCoreEventHandler::Trigger_OnHatchOpen(this);
	}

	void CloseHatch()
	{
		bHatchOpen = false;
		CloseHatchForceComp.RemoveDisabler(this);
		OpenHatchForceComp.AddDisabler(this);

		USkylineCrusherCoreEventHandler::Trigger_OnHatchClose(this);
	}

	void ActivateBladeTarget()
	{
		BladeCombatTargetComp.Enable(this);
		BladeCollison.RemoveComponentCollisionBlocker(this);
	}

	void DeactivateBladeTarget()
	{
		BladeCombatTargetComp.Disable(this);
		BladeCollison.AddComponentCollisionBlocker(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBladeHit(FGravityBladeHitData HitData) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnWhipImpact(FGravityWhipImpactData ImpactData) {}
};