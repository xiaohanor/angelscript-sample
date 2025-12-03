class AMeltdownBossBattleFlowingSplineWave : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float Speed = 150;

	float CurrentSplineDistance;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveLaserLike;
	default MoveLaserLike.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = Spline.Spline;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);
		//SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));

		MoveLaserLike.BindUpdate(this, n"OnUpdate");
		MoveLaserLike.BindFinished(this, n"OnFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));
	}

	UFUNCTION()
	void BP_StartTimeLike()
	{
		MoveLaserLike.PlayFromStart();
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