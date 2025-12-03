class ASkylineDaClubCatwalkWire : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.Friction = 3.0;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinZ = -500.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = FVector::UpVector * 1500.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UGravityWhipTargetComponent WhipTargetComp;
	default WhipTargetComp.MaximumDistance = 2000.0;
	default WhipTargetComp.MaximumAngle = 60.0;

	UPROPERTY(DefaultComponent, Attach = WhipTargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::ControlledDrag;
	default WhipResponseComp.ForceMultiplier = 0.5;
	default WhipResponseComp.ImpulseMultiplier = 0.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxPhysicsComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleConstrainHit");
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		ForceComp.AddDisabler(UserComponent);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ForceComp.RemoveDisabler(UserComponent);
	}

	UFUNCTION()
	private void HandleConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}
};