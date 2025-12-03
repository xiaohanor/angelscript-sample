UCLASS(Abstract)
class USkylineFireTruckLadderEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnfold()
	{
	}
};


event void FSkylineFireTruckLadderOnFullyExtendedSignature();
class ASkylineFireTruckLadder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsSpringConstraint SpringComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent ResponseComp;
	default ResponseComp.MouseCursorForceMultiplier = 1.0;
	default ResponseComp.bMouseCursorTreatDragAsControl = true;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY()
	FSkylineFireTruckLadderOnFullyExtendedSignature OnExtended();

	UPROPERTY(EditAnywhere)
	ALadder LadderA;

	UPROPERTY(EditAnywhere)
	ALadder LadderB;

	UPROPERTY(EditAnywhere)
	APerchSpline PerchSpline;

	UPROPERTY(EditAnywhere)
	APerchPointActor PerchPoint;

	UPROPERTY(EditAnywhere)
	ADeathVolume DeathVolume;

	bool bIsUnfolded = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpdateState();

		Disable();

		ResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");

		RotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleMinConstraintHit");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleMaxConstraintHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!WhipTarget.IsDisabled() && Math::RadiansToDegrees(RotateComp.CurrentRotation) < RotateComp.ConstrainAngleMin * 0.5)
		{
			WhipTarget.Disable(this);
			ForceComp.RemoveDisabler(this);
			SpringComp.AddDisabler(this);
		
			FHazePointOfInterestFocusTargetInfo FocusTarget;
			FocusTarget.SetFocusToComponent(WhipTarget);

			FApplyPointOfInterestSettings PoiSetting;
			PoiSetting.Duration = 1.0;
			Game::Zoe.ApplyPointOfInterest(this, FocusTarget, PoiSetting, 1.0, EHazeCameraPriority::VeryHigh);
		
			USkylineFireTruckLadderEventHandler::Trigger_OnUnfold(this);
		}
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ForceComp.RemoveDisabler(UserComponent);
		SpringComp.RemoveDisabler(UserComponent);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ForceComp.AddDisabler(UserComponent);
		SpringComp.AddDisabler(UserComponent);
	}

	UFUNCTION()
	private void HandleMinConstraintHit(float Strength)
	{
		if (bIsUnfolded)
			return;

		InterfaceComp.TriggerActivate();
		OnExtended.Broadcast();
		bIsUnfolded = true;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		UpdateState();
	}

	UFUNCTION()
	private void HandleMaxConstraintHit(float Strength)
	{
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Enable();
	}

	UFUNCTION()
	void Enable()
	{
		WhipTarget.Enable(this);
		LadderA.Disable(this);
		SpringComp.RemoveDisabler(this);

		if (DeathVolume != nullptr)
			DeathVolume.EnableDeathVolume(this);
	}

	void Disable()
	{
		WhipTarget.Disable(this);
		ForceComp.AddDisabler(this);
		SpringComp.AddDisabler(this);

		if (DeathVolume != nullptr)
			DeathVolume.DisableDeathVolume(this);
	}

	void UpdateState()
	{
		if (bIsUnfolded)
		{
			LadderA.Disable(this);
			LadderB.Enable(this);

			if (PerchSpline != nullptr)
				PerchSpline.EnablePerchSpline(this);

			if (PerchPoint != nullptr)
				PerchPoint.EnablePerchPoint(this);
		}
		else
		{
			LadderA.Enable(this);
			LadderB.Disable(this);

			if (PerchSpline != nullptr)
				PerchSpline.DisablePerchSpline(this);

			if (PerchPoint != nullptr)
				PerchPoint.DisablePerchPoint(this);
		}
	}
};