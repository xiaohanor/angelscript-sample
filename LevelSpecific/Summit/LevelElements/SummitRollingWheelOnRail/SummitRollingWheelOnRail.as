class ASummitRollingWheelOnRail : AHazeActor
{
	UPROPERTY()
	FOnSummitRollingWheelRolled OnWheelRolled;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"SummitTeenDragonRollingWheelOnRailCapability";
	default InteractComp.RelativeLocation = FVector(0, 0, 100);
	default InteractComp.ActionShape.BoxExtents = FVector(200.0, 200.0, 200.0);
	default InteractComp.ActionShapeTransform.Location = FVector(0, 0, 200);
	default InteractComp.FocusShape.SphereRadius = 1000.0;
	default InteractComp.FocusShapeTransform.Location = FVector(0,0, 300.0);

	UPROPERTY(DefaultComponent)
	USceneComponent ExitLocation;
	default ExitLocation.RelativeLocation = FVector(0, -200, 0);


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
	float MaxSpeed = 2000.0;

	/** How fast it takes to reach maximum speed */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float AccelerationDuration = 2.0;

	/** How much it rotates per unit moved
	 * (In degrees of pitch)
	 * */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationPerSpeed = 0.5;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedRollSpeed;

	float CurrentRollPosition = 0.0;

	UHazeSplineComponent SplineComp;
	FSplinePosition CurrentSplinePos;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		SplineComp = UHazeSplineComponent::Get(SplineActor);

	#if EDITOR
		CookChecks::EnsureSplineCanBeUsedOutsideEditor(this, SplineComp);
	#endif

		CurrentSplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(ActorLocation);
		bool bIsForwardOnSpline = CurrentSplinePos.WorldForwardVector.DotProduct(ActorForwardVector) > 0;
		if(!bIsForwardOnSpline)
			CurrentSplinePos.ReverseFacing();

		SyncedRollSpeed.Value = 0.0;
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
		SetActorRotation(Transform.Rotation);
	}

	void MoveWheel(float MoveAmount)
	{
		CurrentSplinePos.Move(MoveAmount);
		CurrentRollPosition += MoveAmount;
		SetActorLocation(CurrentSplinePos.WorldLocation);
		SetActorRotation(CurrentSplinePos.WorldRotation);

		RotationRoot.AddRelativeRotation(FRotator(-MoveAmount * RotationPerSpeed, 0, 0).Quaternion());

		OnWheelRolled.Broadcast(MoveAmount);
	}
};