class ASummitEggHolderRadius : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshEndComp;

	UPROPERTY(EditAnywhere)
	ASummitEggHolder EggHolder;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FVector StartingScale;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;
	FVector EndingScale;

	bool bIsPlaying;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = Mesh.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();
		StartingScale = StartingTransform.GetScale3D();

		EndingTransform = MeshEndComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();
		EndingScale = EndingTransform.GetScale3D();

		// Mesh.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentOverlap");

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		EggHolder.OnEggPlaced.AddUFunction(this, n"EggIsPlaced");
		EggHolder.OnEggRemoved.AddUFunction(this, n"EggIsRemoved");
	}

	
	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		Mesh.SetWorldScale3D(Math::Lerp(StartingScale, EndingScale, Alpha));
		// Mesh.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		// Root.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;


	}

	UFUNCTION()
	void EggIsPlaced()
	{

		MoveAnimation.Play();
	}

	UFUNCTION()
	void EggIsRemoved()
	{

		MoveAnimation.Reverse();
	}

	// UFUNCTION()
	// private void OnComponentOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	//                                          UPrimitiveComponent OtherComp, int OtherBodyIndex,
	//                                          bool bFromSweep, const FHitResult&in SweepResult)
	// {

	// }

};