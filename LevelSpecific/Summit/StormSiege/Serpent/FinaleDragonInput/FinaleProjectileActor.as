event void FOnFinaleProjectileReleased();
event void FOnFinaleProjectileImpacted();

class AFinaleProjectileActor : AHazeActor
{
	UPROPERTY()
	FOnFinaleProjectileReleased OnFinaleProjectileReleased;

	UPROPERTY()
	FOnFinaleProjectileImpacted OnFinaleProjectileImpacted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UHazeSplineComponent Spline;

	FSplinePosition SplinePos;

	FVector TargetLoc;
	
	float MoveSpeed = 2500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = SplineActor.Spline;
		SplinePos = Spline.GetSplinePositionAtSplineDistance(0);
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePos.Move(MoveSpeed * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;
		ActorRotation = SplinePos.WorldRotation.Rotator();

		if (SplinePos.CurrentSplineDistance >= Spline.SplineLength - 1.0)
		{
			SetActorHiddenInGame(true);
			SetActorTickEnabled(false);
			OnFinaleProjectileImpacted.Broadcast();
		}
	}

	void ActivateProjectile()
	{
		SetActorHiddenInGame(false);
		SetActorTickEnabled(true);
		OnFinaleProjectileReleased.Broadcast();
	}
}