class ATowerPathPiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMoonMarketBobbingSceneComponent BobbingRoot;

	UPROPERTY(DefaultComponent, Attach = BobbingRoot)
	UFauxPhysicsConeRotateComponent ConeComp;
	default ConeComp.ConeAngle = 15.0;
	default ConeComp.LocalConeDirection = FVector(0,0,-1);

	UPROPERTY(DefaultComponent, Attach = ConeComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;
	default WeightComp.PlayerForce = 70.0;
	default WeightComp.PlayerImpulseScale = 0.01;

	FVector TargetPosition;
	FVector OffsetPosition = FVector(0,0,-2500);
	FHazeAcceleratedVector AccelVec;

	UPROPERTY(EditInstanceOnly)
	float DelayTime = 0.0;

	bool bMoveActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetPosition = ActorLocation;
		OffsetPosition += ActorLocation;
		ActorLocation = OffsetPosition;
		AccelVec.SnapTo(OffsetPosition);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bMoveActive)
			return;

		if (DelayTime > 0.0)
		{
			DelayTime -= DeltaSeconds;
			return;
		}

		AccelVec.AccelerateTo(TargetPosition, 2.0, DeltaSeconds);
		ActorLocation = AccelVec.Value;
	}

	UFUNCTION()
	void ActivatePathPiece()
	{
		bMoveActive = true;
	}
};