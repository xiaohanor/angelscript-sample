event void FOnEnemyLanded();

class AMeltdownScreenWalkEnemySplineLauncher : AHazeActor
{

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float Speed = 6000;

	UPROPERTY()
	bool bIsDestroyed;

	UPROPERTY()
	float CurrentSplineDistance;

	UPROPERTY()
	FOnEnemyLanded EnemyLanded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = Spline.Spline;
		ActorRotation = FRotator(0,Math::RandRange(0.0,350.0),0);

		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintCallable)
	void LaunchMissile()
	{
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
	}
	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	AddActorWorldOffset(ActorForwardVector * Speed);
		CurrentSplineDistance += Speed * DeltaSeconds;

		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDistance);

		SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));

			if(CurrentSplineDistance >= SplineComp.SplineLength)
			{
				EnemyLanded.Broadcast();
				AddActorDisable(this);
			}

	}
};