class AMeltdownBossPhaseOneStraightLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LaserCube;

	UPROPERTY(DefaultComponent, Attach = LaserCube)
	UStaticMeshComponent LaserBeam;

	UPROPERTY(DefaultComponent)
	UBillboardComponent LaserTarget;

	UPROPERTY(EditAnywhere)
	float Speed = 20;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY()
	FVector LaserStart;

	UPROPERTY(EditAnywhere)
	FVector LaserEnd;

	UPROPERTY()
	FVector LaserStartPosition;

	UPROPERTY()
	FVector LaserEndPosition;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike LaserLike;
	default LaserLike.Duration = 1;
	default LaserLike.UseLinearCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike LaserMove;
	default LaserMove.Duration = 3;
	default LaserMove.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserStartPosition = LaserCube.RelativeLocation;

		LaserEndPosition = LaserTarget.RelativeLocation;

		LaserBeam.SetWorldScale3D(LaserStart);

		LaserStart = FVector(1,1,0);

	}
};