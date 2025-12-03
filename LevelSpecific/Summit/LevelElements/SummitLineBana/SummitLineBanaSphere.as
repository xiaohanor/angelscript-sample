class ASummitLineBanaSphere : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent RollingRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"SummitTeenDragonLineBanaSphereRollingCapability";
	default InteractComp.RelativeLocation = FVector(0, 0, 0);
	default InteractComp.ActionShape.BoxExtents = FVector(400.0, 400.0, 400.0);
	default InteractComp.ActionShapeTransform.Location = FVector(0, 0, 200);
	default InteractComp.FocusShape.SphereRadius = 1000.0;
	default InteractComp.FocusShapeTransform.Location = FVector(0,0, 300.0);

	/** Actor which has a spline component on it.
	 * (OBS! Important to check the bIsGameplaySpline on the component)*/
	UPROPERTY(EditAnywhere, Category = "Setup")
	AActor SplineActor;


	/** Camera which is active when you are interacting with the wheel */
	UPROPERTY(EditAnywhere, Category = "Settings")
	AHazeCameraActor Camera;

	/** The maximum speed of the wheel
	 * (Translation, not rotation)
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxSpeed = 1000.0;

	/** How fast it takes to reach maximum speed */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float AccelerationDuration = 6.0;

	/** How much it rotates per unit moved
	 * (In degrees of pitch)
	 * */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationPerSpeed = 0.3;

	UHazeSplineComponent SplineComp;
	FSplinePosition CurrentSplinePos;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		SplineComp = UHazeSplineComponent::Get(SplineActor);

		if (Camera != nullptr)
			Camera.AttachToComponent(RotationRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

	#if EDITOR
		CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, SplineComp);
	#endif

		CurrentSplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(ActorLocation);
		bool bIsForwardOnSpline = CurrentSplinePos.WorldForwardVector.DotProduct(ActorForwardVector) > 0;
		if(!bIsForwardOnSpline)
			CurrentSplinePos.ReverseFacing();
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void SnapToSpline()
	{
		if(SplineActor == nullptr)
			return;
	
		auto Spline = UHazeSplineComponent::Get(SplineActor);
		if(Spline == nullptr)
			return;

		auto Transform = Spline.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
		SetActorLocation(Transform.Location);
		RotationRoot.SetWorldRotation(Transform.Rotation);
	}

	void RollSphere(float MoveAmount)
	{
		CurrentSplinePos.Move(MoveAmount);
		SetActorLocation(CurrentSplinePos.WorldLocation);
		RotationRoot.SetWorldRotation(CurrentSplinePos.WorldRotation);

		RollingRoot.AddRelativeRotation(FRotator(-MoveAmount * RotationPerSpeed, 0, 0).Quaternion());
	}
};