class ATundraRiverBoulderChaseTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FP_ConeRotationComp;

	UPROPERTY(DefaultComponent, Attach = FP_ConeRotationComp)
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = MovingRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCableComponent Cable;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBillboardComponent EndOfCableLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent TargetLocation;

	UPROPERTY(EditInstanceOnly)
	float FallDuration = 1.5;

	bool bHasBeenTriggered = false;
	FVector StartLocation;
	FVector EndLocation;

	UPROPERTY(EditInstanceOnly)
	float CableLength = 700;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 1;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UFUNCTION(CallInEditor)
	void SetCableLength()
	{
		MovingRoot.RelativeLocation = FVector(0,0,-CableLength);
		Cable.CableLength = CableLength/2;
		Cable.SetAttachEndToComponent(EndOfCableLocation, NAME_None);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveAnimation.SetPlayRate(1/FallDuration);
		Cable.SetAttachEndToComponent(EndOfCableLocation, NAME_None);
		MoveAnimation.BindUpdate(this, n"TL_MoveAnimationUpdate");
		MoveAnimation.BindFinished(this, n"TL_MoveAnimationFinished");
		if(PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"HandleOnPlayerEnter");
		StartLocation = MovingRoot.GetWorldLocation();
		EndLocation = TargetLocation.GetWorldLocation();
	}

	UFUNCTION()
	private void HandleOnPlayerEnter(AHazePlayerCharacter Player)
	{
		Trigger();
	}

	UFUNCTION()
	private void TL_MoveAnimationFinished()
	{
	}

	UFUNCTION()
	private void TL_MoveAnimationUpdate(float CurveValue)
	{
		MovingRoot.SetWorldLocation(Math::Lerp(StartLocation, EndLocation, CurveValue));
	}

	UFUNCTION()
	void Trigger()
	{
		if(!bHasBeenTriggered)
		{
			bHasBeenTriggered = true;
			MoveAnimation.PlayFromStart();
			Cable.bAttachEnd = false;
		}
	}
};