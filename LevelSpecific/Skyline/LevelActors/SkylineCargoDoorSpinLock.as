event void FSkylineCargoDoorSpinLockSprintSignature(ASkylineCargoDoorSpinLockSprint Sprint);

class ASkylineCargoDoorSpinLockSprint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingPivot;

	UPROPERTY(DefaultComponent, Attach = MovingPivot)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent RotateForceComp;	

	UPROPERTY(DefaultComponent, Attach = MovingPivot)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = MovingPivot)
	UCapsuleComponent BladeCollison;

	UPROPERTY(DefaultComponent, Attach = MovingPivot)
	UGravityBladeCombatTargetComponent TargetComp;

	UPROPERTY(DefaultComponent, Attach = MovingPivot)
	UPointLightComponent PointLight;

	UPROPERTY(DefaultComponent, Attach = TargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeCombatResponseComp;
	default BladeCombatResponseComp.InteractionType = EGravityBladeCombatInteractionType::VerticalHigh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	bool bInverseAlpha = false;

	FSkylineCargoDoorSpinLockSprintSignature OnLockSprintBroken;

	FHazeAcceleratedFloat AcceleratedFloat;

	UPROPERTY(EditDefaultsOnly)
	float SprintRetractDistance = -294.0;

	UPROPERTY(EditDefaultsOnly)
	float SprintTranslateDistance = 200.0;

	float SprintRetractTime = 0.0;
	float SprintRetractDelay = 0.4;

	bool bIsActivated = false;
	bool bIsBroken = false;

	float PointLightInitialIntensity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateComp.AddDisabler(this);
		RotateForceComp.AddDisabler(this);

		SetActorControlSide(Game::Mio);
		Deactivate();

		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleBladeHit");
	
		PointLightInitialIntensity = PointLight.Intensity;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsBroken && Time::GameTimeSeconds > SprintRetractTime)
		{
			RotateComp.RemoveDisabler(this);
			RotateForceComp.RemoveDisabler(this);

			AcceleratedFloat.AccelerateTo(SprintRetractDistance, 1.4, DeltaSeconds);
			MovingPivot.RelativeLocation = FVector::RightVector * AcceleratedFloat.Value;
		}

			float Alpha = TranslateComp.RelativeLocation.Y / TranslateComp.MinY;
			PointLight.SetIntensity(PointLightInitialIntensity * Math::Abs(Alpha));

	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if (!bIsActivated)
			return;

		if (HasControl())
			CrumbTriggerBladeHit(HitData);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerBladeHit(FGravityBladeHitData HitData)
	{
		BP_OnBladeHit(HitData);
		BreakLockSprint();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBladeHit(FGravityBladeHitData HitData) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnBreakLockSprint() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnSnapToCompletedState() {}

	UFUNCTION()
	void SnapToCompletedState()
	{
		bIsBroken = true;
		Deactivate();
		BP_OnSnapToCompletedState();
		PointLight.SetVisibility(false);
	}

	UFUNCTION()
	void BreakLockSprint()
	{
		bIsBroken = true;
		Deactivate();
		BP_OnBreakLockSprint();		
		OnLockSprintBroken.Broadcast(this);

		AcceleratedFloat.SnapTo(MovingPivot.RelativeLocation.Y);
		SprintRetractTime = Time::GameTimeSeconds + SprintRetractDelay;
		PointLight.SetVisibility(false);
	}

	void Update(float InAlpha)
	{
		if (bIsBroken)
			return;

		float Alpha = InAlpha;

		if (bInverseAlpha)
			Alpha *= -1.0;

		Alpha = Math::Max(0.0, Alpha);

		MovingPivot.RelativeLocation = FVector::RightVector * SprintTranslateDistance * Alpha;

		if (!bIsActivated && Alpha >= 0.6)
			Activate();

		if (bIsActivated && Alpha < 0.5)
			Deactivate();
	}

	void Activate()
	{
		bIsActivated = true;
		TargetComp.Enable(this);
		BladeCollison.RemoveComponentCollisionBlocker(this);
		ForceComp.Force *= -1.0;
	}

	void Deactivate()
	{
		bIsActivated = false;
		TargetComp.Disable(this);
		BladeCollison.AddComponentCollisionBlocker(this);
		ForceComp.Force *= -1.0;
	}
}

UCLASS(Abstract)
class USkylineCargoDoorSpinLockEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpen()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityWhipGrabbed()
	{
	}		

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityWhipReleased()
	{
	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLockSprintBroken(FSkylineCargoDoorLockSprintBrokenParams Params)
	{
	}
};

event void FSkylineCargoDoorSpinLockSignature();
event void FSkylineCargoDoorSpinLockOpenPOISignature(USceneComponent POITarget);

class ASkylineCargoDoorSpinLock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent, Attach = OutlineComp)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.bConstrain = true;
	default RotateComp.ConstrainAngleMin = -360.0;
	default RotateComp.ConstrainAngleMax = 360.0;
	default RotateComp.SpringStrength = 6.0;
	default RotateComp.Friction = 4.0;
	default RotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	float InitialSpringStrength = 0.0;

	float Alpha = 0.0;

	UPROPERTY(DefaultComponent)
	USceneComponent MovingPivot;

	UPROPERTY(EditDefaultsOnly)
	float TranslateDistance = 200.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxPhysicsComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::ControlledDrag;
	default WhipResponseComp.ImpulseMultiplier = 0.0;
	default WhipResponseComp.ForceMultiplier = 0.3;
	default WhipResponseComp.MouseCursorForceMultiplier = 1.5;
	default WhipResponseComp.bAllowMultiGrab = false;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	TArray<ASkylineCargoDoorSpinLockSprint> LockSprints;

	UPROPERTY()
	FSkylineCargoDoorSpinLockSignature OnOpen;

	UPROPERTY()
	FSkylineCargoDoorSpinLockOpenPOISignature OnOpenWithPOI;

	TArray<UGravityWhipTargetComponent> WhipTargetComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialSpringStrength = RotateComp.SpringStrength;

		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	
		RotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleConstraintHit");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleConstraintHit");

		GetComponentsByClass(WhipTargetComps);

		for (auto LockSprint : LockSprints)
			LockSprint.OnLockSprintBroken.AddUFunction(this, n"HandleLockSprintBroken");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Alpha = Math::GetMappedRangeValueClamped(FVector2D(RotateComp.ConstrainAngleMin, RotateComp.ConstrainAngleMax), FVector2D(-1.0, 1.0), Math::RadiansToDegrees(RotateComp.CurrentRotation));

		MovingPivot.RelativeLocation = FVector::RightVector * TranslateDistance * Alpha;

		for (auto LockSprint : LockSprints)
			LockSprint.Update(Alpha);

//		PrintToScreen("Alpha: " + Alpha, 0.0, FLinearColor::Green);
//		PrintToScreen("CurrentRotation: " + RotateComp.CurrentRotation, 0.0, FLinearColor::Green);

	}

	UFUNCTION()
	private void HandleConstraintHit(float Strength)
	{
		BP_OnConstraintHit(Strength);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnConstraintHit(float Strength)
	{

	}

	UFUNCTION()
	private void HandleLockSprintBroken(ASkylineCargoDoorSpinLockSprint Sprint)
	{	
		FSkylineCargoDoorLockSprintBrokenParams Params;
		Params.SprintLocation = Sprint.MovingPivot.WorldLocation;
		Params.SprintIndex = (Sprint == LockSprints[0]) ? ELockSprintIndex::Right : ELockSprintIndex::Left;
		
		USkylineCargoDoorSpinLockEventHandler::Trigger_OnLockSprintBroken(this, Params);

		for (auto LockSprint : LockSprints)
		{
			if (!LockSprint.bIsBroken)
				return;	
		}

		Open();
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		RotateComp.SpringStrength = 0.0;
		USkylineCargoDoorSpinLockEventHandler::Trigger_OnGravityWhipGrabbed(this);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		RotateComp.SpringStrength = InitialSpringStrength;
		USkylineCargoDoorSpinLockEventHandler::Trigger_OnGravityWhipReleased(this);
	}

	UFUNCTION()
	void Open()
	{		
		auto WhipUserComp = UGravityWhipUserComponent::Get(Game::Zoe);
		if (WhipUserComp != nullptr && WhipUserComp.IsGrabbingAny())
			OnOpenWithPOI.Broadcast(WhipUserComp.GetPrimaryTarget());

		for (auto WhipTargetComp : WhipTargetComps)
			WhipTargetComp.Disable(this);

		InterfaceComp.TriggerActivate();

		BP_OnOpen();

		USkylineCargoDoorSpinLockEventHandler::Trigger_OnOpen(this);
	}

	UFUNCTION()
	void SnapToCompletedState()
	{
		for (auto WhipTargetComp : WhipTargetComps)
			WhipTargetComp.Disable(this);

		for (auto LockSprint : LockSprints)
			LockSprint.SnapToCompletedState();

		BP_OnSnapToCompletedState();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnOpen() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnSnapToCompletedState() {}

	UFUNCTION(DevFunction)
	void DevOpenCargoDoor()
	{
		Open();

		for (auto LockSprint : LockSprints)
			LockSprint.SnapToCompletedState();
	}
};