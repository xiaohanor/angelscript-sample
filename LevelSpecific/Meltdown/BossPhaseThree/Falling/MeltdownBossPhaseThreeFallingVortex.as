class AMeltdownBossPhaseThreeFallingVortex : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent SpinningDebris;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float StartLocation;

	float Endlocation;

	float CurrentSplineDistance;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PTrigger;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveSpline;
	default MoveSpline.Duration = 5.5;
	default MoveSpline.UseLinearCurveZeroToOne();
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = SplineActor.Spline;

		PTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		MoveSpline.BindUpdate(this, n"OnUpdate");

		AddActorDisable(this);
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
			RemoveActorDisable(this);
			MoveSpline.Play();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SpinningDebris.AddLocalRotation(FRotator(10,5,60) * DeltaSeconds);
	}



	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(Math::Lerp(StartLocation,SplineComp.SplineLength, CurrentValue));

	}

};