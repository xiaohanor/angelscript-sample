class AMeltdownScreenWalkChute : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Chute;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ChuteTarget;

	UPROPERTY(EditAnywhere)
	APlayerForceSlideVolume Slide;

	UPROPERTY()
	FHazeTimeLike ChuteMove;
	default ChuteMove.Duration = 1.0;
	default ChuteMove.UseSmoothCurveZeroToOne();


	FRotator ActorStartRotation;

	FRotator ActorTargetRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChuteMove.BindUpdate(this, n"MoveChute");
		ActorStartRotation = ActorRotation;
		ActorTargetRotation = ChuteTarget.WorldRotation;
	}

	UFUNCTION()
	private void MoveChute(float CurrentValue)
	{
		SetActorRotation(Math::LerpShortestPath(ActorStartRotation, ActorTargetRotation, CurrentValue));
	}

	UFUNCTION()
	void StartChute()
	{
		ChuteMove.PlayFromStart();
		Slide.AddActorDisable(this);

	}
};
