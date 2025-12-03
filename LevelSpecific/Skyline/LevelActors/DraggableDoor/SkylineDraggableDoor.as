class ASkylineDraggableDoor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MaxZ = 350.0;
	default TranslateComp.Friction = 6.0;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsSpringConstraint SpringComp;
	default SpringComp.SpringStrength = 4000.0;
	default SpringComp.AnchorOffset = FVector::UpVector * 50.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = FVector::UpVector * 2000.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UGravityWhipTargetComponent WhipTargetComp;

	UPROPERTY(DefaultComponent, Attach = WhipTargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::ControlledDrag;
	default WhipResponseComp.ImpulseMultiplier = 0.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent WhipFauxPhysicsComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	float ActivationTime = 0.0;
	float WhipTargetActivationDelay = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Deactivate();

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");

		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleContraintHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (WhipTargetComp.IsDisabled() && Time::GameTimeSeconds > ActivationTime + WhipTargetActivationDelay)
			WhipTargetComp.Enable(this);

		if (TranslateComp.RelativeLocation.Z > TranslateComp.MaxZ * 0.5)
		{
			SpringComp.AddDisabler(this);
			ForceComp.RemoveDisabler(this);
		}
		else
		{
			SpringComp.RemoveDisabler(this);
			ForceComp.AddDisabler(this);			
		}
	}

	UFUNCTION()
	private void HandleContraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		USkylineDraggableDoorEventHandler::Trigger_OnDraggableDoorConstraintHit(this);
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, ActorLocation, false, this, 400, 600, 1, 1, EHazeSelectPlayer::Both);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Activate();
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		SpringComp.AddDisabler(UserComponent);
		ForceComp.AddDisabler(UserComponent);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		SpringComp.RemoveDisabler(UserComponent);
		ForceComp.RemoveDisabler(UserComponent);
	}

	void Activate()
	{
		ActivationTime = Time::GameTimeSeconds;

		SetActorTickEnabled(true);
		TranslateComp.RemoveDisabler(this);
		BP_Activate();
	}

	void Deactivate()
	{
		ForceComp.AddDisabler(this);
		TranslateComp.AddDisabler(this);
		WhipTargetComp.Disable(this);
		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() {}
};