event void AsteroidStarted();
event void AsteroidInPosition();

UCLASS(Abstract)
class AMeltdownBossPhaseTwoFlyingCube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent FlyingAsteroid;
	default FlyingAsteroid.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseTwoMeteorPool TargetAsteroid;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem SpawnEffect;

	FVector StartLocation;
	FVector TargetLocation;

	UPROPERTY()
	AsteroidStarted AsteroidInMotion;

	UPROPERTY()
	AsteroidInPosition AsteroidLinedUp;

	FHazeTimeLike StartAsteroid;
	default StartAsteroid.Duration = 2.0;
	default StartAsteroid.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		StartLocation = ActorLocation;
		TargetLocation = TargetAsteroid.Asteroid.WorldLocation;

		StartAsteroid.BindFinished(this, n"OnAsteroidFinished");
		StartAsteroid.BindUpdate(this, n"OnAsteroidUpdate");
	}

	UFUNCTION()
	private void OnAsteroidUpdate(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(StartLocation, TargetLocation, CurrentValue));
	}

	UFUNCTION()
	private void OnAsteroidFinished()
	{
		AsteroidLinedUp.Broadcast();
		ActorLocation = StartLocation;
		AddActorDisable(this);
	}


	UFUNCTION(BlueprintCallable)
	void LaunchAsteroid()
	{
		RemoveActorDisable(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SpawnEffect,FlyingAsteroid.WorldLocation);
		StartAsteroid.PlayFromStart();
		AsteroidInMotion.Broadcast();
	}
};
