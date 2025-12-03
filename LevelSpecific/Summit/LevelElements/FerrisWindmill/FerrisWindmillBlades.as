class AFerrisWindmillBlades : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WheelRotationPoint;

	UPROPERTY(DefaultComponent, Attach = WheelRotationPoint)
	USceneComponent PlatformFollowPoint;

	UPROPERTY(DefaultComponent, Attach = WheelRotationPoint)
	USceneComponent PlatformFollowPoint2;

	UPROPERTY(DefaultComponent, Attach = WheelRotationPoint)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent, Attach = WheelRotationPoint)
	USceneComponent PlatformRoot2;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot2)
	UStaticMeshComponent Platform2;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"FerrisWindmillBladeRotationCapability");

	UPROPERTY(EditAnywhere, Category = "Roll Rotate")
	FRuntimeFloatCurve RollRotationCurve;
	default RollRotationCurve.AddDefaultKey(0.0, 0.0);
	default RollRotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	float RotationAmountPerHit = 60.0;

	UPROPERTY(EditAnywhere)
	float MoveDownAmount = 1500.0;

	FQuat TargetQuat;
	FQuat StartQuat;

	FVector TargetLocation;
	FVector StartingLocation;
	FRotator TargetRotation;
	FRotator StartingRotation;

	bool bStartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartQuat = WheelRotationPoint.RelativeRotation.Quaternion();
		StartingRotation = ActorRotation - FRotator(0,35,0);
		TargetRotation = ActorRotation;
		ActorRotation = StartingRotation;

		StartingLocation = ActorLocation;
		TargetLocation = ActorLocation - FVector::UpVector * MoveDownAmount;
	}

	UFUNCTION()
	void StartRotation()
	{
		bStartRotation = true;
	}

	void AddRotationOnImpact(bool bIsRight)
	{
		float Multplier = 1;

		if (!bIsRight)
			Multplier = -1;

		TargetQuat *= FRotator(RotationAmountPerHit * Multplier, 0, 0).Quaternion();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FVector StartLoc = ActorLocation + ActorRightVector * 300;
		Debug::DrawDebugLine(StartLoc, StartLoc + -FVector::UpVector * MoveDownAmount, FLinearColor::Red, 20);
	}
#endif
};