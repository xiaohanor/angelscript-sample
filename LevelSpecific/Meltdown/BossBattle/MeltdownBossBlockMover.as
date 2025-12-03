class AMeltdownBossBlockMover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TargetLocation;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent SecondTargetLocation;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ThirdTargetLocation;

	UPROPERTY()
	FVector StartPos;

	UPROPERTY()
	FVector FirstEndPos;
	UPROPERTY()
	FVector SecondEndPos;
	UPROPERTY()
	FVector ThirdEndPos;

	UPROPERTY()
	FRotator StartRot;

	UPROPERTY()
	FRotator FirstEndRot;

	UPROPERTY(EditAnywhere)
	AMeltdownBossCubeGrid CubeGrid;

	UPROPERTY()
	FHazeTimeLike MoveCubeLike;
	default MoveCubeLike.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPos = CubeGrid.ActorLocation;
		StartRot = CubeGrid.ActorRotation;

		FirstEndPos = TargetLocation.WorldLocation;
		FirstEndRot = TargetLocation.WorldRotation;

		SecondEndPos = SecondTargetLocation.WorldLocation;

		ThirdEndPos = ThirdTargetLocation.WorldLocation;
	}

};