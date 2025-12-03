class ASanctuaryCoopFlyingTempHydraProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	AActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent TelegraphHazeSphere;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GhostBallRoot;
	
	FVector SplineRelativeLocation;

	float TelegraphDuration = 2.0;

	FVector Direction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(SplineActor);
		AddActorDisable(this);
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);
		SetSplineRelativeLocation();

		FVector Location = SplineComp.GetClosestSplineWorldLocationToWorldLocation(Game::Mio.ActorLocation) + SplineRelativeLocation;
		SetActorLocation(Location);
		GhostBallRoot.SetRelativeLocation(FVector::UpVector * -10000.0);

		QueueComp.Duration(TelegraphDuration, this, n"GhostProjectileUpdate");
		QueueComp.Event(this, n"GhostProjectilePassed");
		QueueComp.Duration(TelegraphDuration / 4, this, n"GhostProjectileDisapear");
		QueueComp.Event(this, n"GhostProjectileFinished");
		BP_Activate();
	}

	UFUNCTION()
	private void GhostProjectileUpdate(float Alpha)
	{
		FVector Location = SplineComp.GetClosestSplineWorldLocationToWorldLocation(Game::Mio.ActorLocation) - SplineRelativeLocation;
		SetActorLocation(Location);

		TelegraphHazeSphere.SetOpacityValue(Alpha * 0.5);

		GhostBallRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(-20000.0, 0.0, Alpha));
	}

	UFUNCTION()
	private void GhostProjectilePassed()
	{
		SetActorRotation(FRotator::ZeroRotator);
	}

	UFUNCTION()
	private void GhostProjectileDisapear(float Alpha)
	{
		FVector Location = SplineComp.GetClosestSplineWorldLocationToWorldLocation(Game::Mio.ActorLocation) - SplineRelativeLocation;
		SetActorLocation(Location);

		TelegraphHazeSphere.SetOpacityValue(Math::Lerp(0.5, 0.0, Alpha));

		GhostBallRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(0.0, 5000.0, Alpha));
	}

	UFUNCTION()
	private void GhostProjectileFinished()
	{
		BP_Explode();
		AddActorDisable(this);
	}

	private void SetSplineRelativeLocation()
	{
		FVector ClosestSplineLocation = SplineComp.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
		SplineRelativeLocation = ClosestSplineLocation - ActorLocation;

		Direction = ((ClosestSplineLocation + FVector::UpVector * 3000.0) - ActorLocation).GetSafeNormal();
		FRotator Rotation = FRotator::MakeFromZ(Direction);

		SetActorRotation(Rotation);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};