class ASoftSplitDoubleDoor : AWorldLinkDoubleActor
{
	
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UBillboardComponent Laser01;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UBillboardComponent Laser02;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UBillboardComponent Laser03;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UBillboardComponent MeshComp_Fantasy;

	UPROPERTY()
	FHazeTimeLike  DoorAnimation;
	default DoorAnimation.Duration = 1.0;
	default DoorAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	float MoveDistance;

	FVector StartLocation;
	FVector EndLocation;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartLocation = ActorLocation;

		EndLocation = ActorLocation - FVector(0,0,MoveDistance);

		DoorAnimation.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION(BlueprintEvent)
	void MoveDoor()
	{
	
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		SetActorRelativeLocation(Math::Lerp(StartLocation, EndLocation, Alpha));
	}

};