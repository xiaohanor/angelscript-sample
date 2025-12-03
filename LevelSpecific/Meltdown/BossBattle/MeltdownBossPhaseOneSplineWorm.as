class AMeltdownBossPhaseOneSplineWorm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	float Speed = 150;

	float CurrentSplineDistance;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LaserMesh;

	UPROPERTY(EditAnywhere)
	FVector StartLaser;

	UPROPERTY(EditAnywhere)
	FVector EndLaser;

	UPROPERTY()
	FHazeTimeLike MoveLaserLike;
	default MoveLaserLike.UseLinearCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike StartLaserLike;
	default StartLaserLike.Duration = 1;
	default StartLaserLike.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);
		SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));

		MoveLaserLike.BindUpdate(this, n"OnUpdate");
		MoveLaserLike.BindFinished(this, n"OnFinished");

		StartLaserLike.BindUpdate(this, n"OnUpdateLaser");
		StartLaserLike.BindFinished(this, n"OnFinishedLaser");
		BP_StartTimeLike();
	}
	UFUNCTION()
	private void OnUpdateLaser(float Laservalue)
	{
		LaserMesh.SetRelativeScale3D(Math::Lerp(StartLaser,EndLaser,Laservalue));
	}

	UFUNCTION(BlueprintEvent)
	private void OnFinishedLaser()
	{	
		MoveLaserLike.PlayFromStart();
	}

	UFUNCTION()
	void BP_StartTimeLike()
	{
		StartLaserLike.PlayFromStart();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(Math::Lerp(CurrentSplineDistance,SplineComp.SplineLength, CurrentValue));
	}

	UFUNCTION()
	private void OnFinished()
	{
		DestroyActor();
	}
};
