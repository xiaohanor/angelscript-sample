class AEvergreenSwingingPoleClimb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent EditorBillboard;
	default EditorBillboard.SetSpriteName("S_Player");
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;
	default AxisRotateComp.LocalRotationAxis = FVector::ForwardVector;
	default AxisRotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromMioControl;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UFauxPhysicsWeightComponent WeightComp;
	default WeightComp.MassScale = BaseMassScale;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditAnywhere)
	APoleClimbActor PoleClimbToAttach;

	UPROPERTY(EditAnywhere)
	float ImpulseToApply = 300.0;

	/* The default mass scale of the weight component when the pole is empty. */
	UPROPERTY(EditAnywhere)
	float BaseMassScale = 0.3;

	/* The mass scale of the weight component when the player is climbing on the pole. */
	UPROPERTY(EditAnywhere)
	float MonkeyMassScale = 0.4;

	int CurrentSwayDirection = 0;

#if EDITOR
	UFUNCTION(CallInEditor)
	void SnapPoleToActor()
	{
		Editor::BeginTransaction("Snap Pole To Actor");
		PoleClimbToAttach.Modify();
		PoleClimbToAttach.ActorLocation = AxisRotateComp.WorldLocation;
		PoleClimbToAttach.ActorRotation = FRotator::MakeFromZ(FVector::DownVector);
		Editor::EndTransaction();
	}

	UFUNCTION(CallInEditor)
	void SnapActorToPole()
	{
		Editor::BeginTransaction("Snap Actor To Pole");
		Modify();
		PoleClimbToAttach.Modify();
		ActorLocation = PoleClimbToAttach.ActorLocation;
		PoleClimbToAttach.ActorRotation = FRotator::MakeFromZ(FVector::DownVector);
		Editor::EndTransaction();
		Editor::SelectActor(this);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		devCheck(PoleClimbToAttach != nullptr, "EvergreenSwingingPoleClimb does not have an assigned PoleClimbActor");
		PoleClimbToAttach.AttachToComponent(AxisRotateComp, NAME_None, EAttachmentRule::SnapToTarget);
		PoleClimbToAttach.ActorRotation = FRotator::MakeFromZ(FVector::DownVector);
		WeightComp.RelativeLocation = FVector::DownVector * PoleClimbToAttach.Height;

		PoleClimbToAttach.OnStartPoleClimb.AddUFunction(this, n"OnStartClimbing");
		PoleClimbToAttach.OnStopPoleClimb.AddUFunction(this, n"OnStopClimbing");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Math::Abs(SwayVelocity) < 0.001)
		{
			CurrentSwayDirection = 0;
			return;
		}

		int Sign = int(Math::Sign(SwayVelocity));
		if(Sign != CurrentSwayDirection)
			UEvergreenSwingingPoleClimbEffectHandler::Trigger_OnStartSwayingInDirection(this);
		CurrentSwayDirection = Sign;
	}

	UFUNCTION()
	private void OnStartClimbing(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		FVector ImpulseDirection = (PoleClimbActor.ActorLocation - Player.ActorLocation).VectorPlaneProject(PoleClimbActor.ActorUpVector).GetSafeNormal();
		AxisRotateComp.ApplyImpulse(Player.ActorCenterLocation, ImpulseDirection * ImpulseToApply);
		WeightComp.MassScale = MonkeyMassScale;
		UEvergreenSwingingPoleClimbEffectHandler::Trigger_OnMonkeyAttachToPole(this);
	}

	UFUNCTION()
	private void OnStopClimbing(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		WeightComp.MassScale = BaseMassScale;
		UEvergreenSwingingPoleClimbEffectHandler::Trigger_OnMonkeyJumpOff(this);
	}

	UFUNCTION(BlueprintPure)
	float GetSwayVelocity() const property
	{
		return AxisRotateComp.Velocity;
	}
}