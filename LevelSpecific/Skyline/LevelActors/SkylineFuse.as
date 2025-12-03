event void FSkylineFuseSignature();

class ASkylineFuse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;
	default FauxPhysicsTranslateComponent.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UCapsuleComponent CapsuleComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UFauxPhysicsForceComponent FauxPhysicsForceComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	USceneComponent AnimationRoot;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	USceneComponent FuseRoot;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::ControlledDrag;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComponent;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Animation;
	default Animation.bCurveUseNormalizedTime = true;
	default Animation.Curve.AddDefaultKey(0.0, 0.0);
	default Animation.Curve.AddDefaultKey(1.0, 1.0);

	bool bExposed;

	UPROPERTY(BlueprintReadOnly)
	bool bIsDisabled = false;

	UPROPERTY(EditAnywhere)
	bool bHideOnDisabled = false;

	UPROPERTY(EditAnywhere)
	bool bReactivate = true;

	UPROPERTY(EditAnywhere)
	float ReactivateTime = 5.0;

	FTimerHandle Timer;

	UPROPERTY()
	FSkylineFuseSignature OnFuseDisabled;

	UPROPERTY()
	FSkylineFuseSignature OnFuseEnabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleWhipGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleWhipReleased");

		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");

		FauxPhysicsTranslateComponent.OnConstraintHit.AddUFunction(this, n"HandleContrainHit");

		Animation.BindUpdate(this, n"AnimationUpdate");
		Animation.BindFinished(this, n"AnimationFinished");

		Animation.PlayRate = 20.0;

		GravityBladeTargetComponent.Disable(this);
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		// Check whether it was exposed for Mio when she hit it,
		// so it doesn't get desynced if Zoe has already released it.
		if (Game::Mio.HasControl() && bExposed)
			CrumbFuseHit();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFuseHit()
	{
		BPFuseHit();
		InterfaceComponent.TriggerActivate();
		Disable();

		if (bReactivate)
			Timer::SetTimer(this, n"Enable", ReactivateTime);
	}

	UFUNCTION()
	void Disable()
	{
		bIsDisabled = true;

		//InterfaceComponent.TriggerDeactivate();

		OnFuseDisabled.Broadcast();
		BPDisable();

		GravityWhipTargetComponent.Disable(this);
		GravityBladeTargetComponent.Disable(this);
		FuseRoot.SetHiddenInGame(true, true);
		SetActorEnableCollision(false);

		if (bHideOnDisabled)
			AddActorDisable(this);
	}

	UFUNCTION()
	void Enable()
	{
		bIsDisabled = false;

		
		//InterfaceComponent.TriggerActivate();
		OnFuseEnabled.Broadcast();
		BPEnable();

		GravityWhipTargetComponent.Enable(this);

		if (bExposed)
			GravityBladeTargetComponent.Enable(this);

		FuseRoot.SetHiddenInGame(false, true);
		SetActorEnableCollision(true);
	}

	UFUNCTION(BlueprintEvent)
	void BPFuseHit()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BPEnable()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BPDisable()
	{

	}


	UFUNCTION()
	private void HandleContrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge != EFauxPhysicsTranslateConstraintEdge::AxisZ_Max)
		{
			FSkylineFuseConstrainHitParams Params;
			Params.Strength = HitStrength;

			USkylineFuseEventHandler::Trigger_OnHitBottom(this, Params);
			return;
		}

		FauxPhysicsTranslateComponent.AddDisabler(this);
		GravityBladeTargetComponent.Enable(this);

		Animation.Play();
		USkylineFuseEventHandler::Trigger_OnCoverOpen(this);

		bExposed = true;
	}

	UFUNCTION()
	private void HandleWhipGrabbed(UGravityWhipUserComponent UserComponent,
	                               UGravityWhipTargetComponent TargetComponent,
								   TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		FauxPhysicsForceComponent.AddDisabler(this);
	}

	UFUNCTION()
	private void HandleWhipReleased(UGravityWhipUserComponent UserComponent,
	                                UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		FauxPhysicsForceComponent.RemoveDisabler(this);
		GravityBladeTargetComponent.Disable(this);

		Animation.Reverse();
		USkylineFuseEventHandler::Trigger_OnCoverClose(this);
	}

	UFUNCTION()
	private void AnimationUpdate(float Value)
	{
		AnimationRoot.RelativeLocation = FVector::UpVector * Value * -140.0;
	}

	UFUNCTION()
	private void AnimationFinished()
	{
		if (Animation.IsReversed())
		{
			FauxPhysicsTranslateComponent.RemoveDisabler(this);
			bExposed = false;
		}
	}
}

struct FSkylineFuseConstrainHitParams
{
	UPROPERTY()
	float Strength = 0.0;
}

class USkylineFuseEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnCoverOpen()  {}

	UFUNCTION(BlueprintEvent)
	void OnCoverClose()  {}

	UFUNCTION(BlueprintEvent)
	void OnHitBottom(FSkylineFuseConstrainHitParams Params)  {}
}