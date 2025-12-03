event void FSpawnWorm();

class AMeltdownBossPhaseTwoFireWorm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Cube01;

	UPROPERTY()
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	float StartDelay;

	UPROPERTY()
	float ExplodeDelay;

	float Cube01Start;

	float CurrentSplineDistance;

	UPROPERTY()
	FSpawnWorm SpawnWorm;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveWorm;
	default MoveWorm.Duration = 10.0;
	default MoveWorm.UseSmoothCurveZeroToOne(); 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		MoveWorm.BindUpdate(this, n"OnUpdate");

		MoveWorm.BindFinished(this, n"OnFinished");

		MoveWorm.Play();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		CurrentSplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(Math::Lerp(Cube01Start,SplineComp.SplineLength, CurrentValue));

		Cube01.SetWorldRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));
	}

	UFUNCTION()
	private void OnFinished()
	{
		AddActorDisable(this);
		SpawnRealWorm();
	}

	UFUNCTION(BlueprintEvent)
	void SpawnRealWorm()
	{
		SpawnWorm.Broadcast();
	}

};