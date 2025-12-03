class ASkylineSlideChasePlayerFocusActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	FHazeAcceleratedVector AccelVector;

	UPROPERTY(EditAnywhere)
	float AccelDuration = 0.75;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccelVector.SnapTo(ActorLocation);
		Spline = SplineActor.Spline;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector BetweenPoint = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;

		if (Game::Mio.IsPlayerDead())
			BetweenPoint = Game::Zoe.ActorLocation;
		else if (Game::Zoe.IsPlayerDead())
			BetweenPoint = Game::Mio.ActorLocation;

		FVector SplineLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(BetweenPoint);
		BetweenPoint = FVector(BetweenPoint.X, BetweenPoint.Y, SplineLocation.Z);
		AccelVector.AccelerateTo(BetweenPoint, AccelDuration, DeltaSeconds);
		ActorLocation = AccelVector.Value;
	}

	UFUNCTION()
	void SetSlideChaseActorActive(bool bIsActive)
	{
		SetActorTickEnabled(bIsActive);

		if (bIsActive)
			AccelVector.SnapTo((Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2);
	}
};