class ASkylineHighwayCargoTruckHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.LocalRotationAxis = FVector::RightVector;
	default RotateComp.bConstrain = true;
	default RotateComp.ConstrainAngleMin = 0.0;
	default RotateComp.ConstrainAngleMax = 90.0;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsSpringConstraint SpringComp;
	default SpringComp.RelativeLocation = FVector::UpVector * 500.0;
	default SpringComp.bOnlyApplySpringToThisActor = true;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UGravityWhipTargetComponent TargetComp;
	default TargetComp.MaximumDistance = 2500.0;

	UPROPERTY(DefaultComponent, Attach = TargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.RelativeLocation = FVector::UpVector * 500.0;
	default ForceComp.bWorldSpace = false;
	default ForceComp.Force = FVector::ForwardVector * 500.0;
	default ForceComp.bOnlyApplyForceToThisActor = true;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxPhysicsComp;
	default WhipFauxPhysicsComp.bOnlyApplyForceToThisActor = true;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	bool bIsOpen = false;

	UPROPERTY(Category = Audio)
	UHazeAudioEvent HatchGrabbedEvent;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UGrapplePointComponent GP;

	UPROPERTY(Category = Audio)
	FHazeAudioFireForgetEventParams PostEventParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);

		ResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		ResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");

		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleMaxConstraintHit");
		PostEventParams.AttachComponent = Root;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Math::RadiansToDegrees(RotateComp.CurrentRotation) > RotateComp.ConstrainAngleMax * 0.5)
		{
			TargetComp.Disable(this);
			ForceComp.RemoveDisabler(this);
			SpringComp.AddDisabler(this);
		}
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		SpringComp.AddDisabler(UserComponent);

		if(HatchGrabbedEvent != nullptr)
			AudioComponent::PostFireForget(HatchGrabbedEvent, PostEventParams);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		SpringComp.RemoveDisabler(UserComponent);
	}

	UFUNCTION()
	private void HandleMaxConstraintHit(float Strength)
	{
		bIsOpen = true;

		InterfaceComp.TriggerActivate();

		BP_OnOpen();
	}

	UFUNCTION(BlueprintCallable)
	void EnableGrappleMio()
	{
		GP.SetUsableByPlayers(EHazeSelectPlayer::Both);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnOpen() { }
};