class ASummitMovementResponseWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 35000.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActor MovingActor;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationDegreesPerUnitMoved = 0.1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector ActorsDirectionWhichCountsAsForward = FVector(0.0, 0.0, -1.0);

	FVector ActorsPreviousLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(MovingActor == nullptr)
			return;
		ActorsPreviousLocation = MovingActor.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MovingActor == nullptr)
			return;
		
		FVector MovedDelta = MovingActor.ActorLocation - ActorsPreviousLocation;
		FVector ForwardDir = MovingActor.ActorTransform.TransformVectorNoScale(ActorsDirectionWhichCountsAsForward);
		float MovedDist = MovedDelta.DotProduct(ForwardDir);
		RotateRoot.AddLocalRotation(FRotator(0.0, 0.0, MovedDist * RotationDegreesPerUnitMoved));

		ActorsPreviousLocation = MovingActor.ActorLocation;
	}
};