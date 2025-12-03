class AMeltdownBossPhaseOneSwingLaser : AHazeActor
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
	APlayerTrigger Trigger;

	UPROPERTY()
	FVector LaserStart;

	UPROPERTY(EditAnywhere)
	FVector LaserEnd;

	UPROPERTY(EditAnywhere)
	FRotator LaserStartRotation;

	UPROPERTY(EditAnywhere)
	FRotator LaserEndRotation;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike LaserLike;
	default LaserLike.Duration = 2;
	default LaserLike.UseLinearCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike LaserMove;
	default LaserMove.Duration = 4;
	default LaserMove.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		LaserBeam.SetWorldScale3D(LaserStart);

		LaserStart = FVector(1,1,0);

	}


	UFUNCTION()
	private void MoveFinished()
	{
		AddActorDisable(this);
	}
};