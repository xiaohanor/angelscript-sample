class AMeltdownBossPhaseThreeLasers : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Laser;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Ptrigger;

	FVector LaserStart;
	FVector LaserEnd;

	FRotator LaserStartRotation;
	FRotator LaserEndRotation;

	UPROPERTY(EditAnywhere)
	float DelayStart;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LaserTarget;
	default LaserTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default LaserTarget.SetHiddenInGame(true);

	FHazeTimeLike MoveLaser;
	default MoveLaser.Duration = 3.0;
	default MoveLaser.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveLaser.BindUpdate(this, n"LaserMover");

		if(Ptrigger != nullptr)
		Ptrigger.OnActorBeginOverlap.AddUFunction(this, n"Overlap");

		LaserStart = Laser.WorldLocation;

		LaserEnd = LaserTarget.WorldLocation;

		LaserStartRotation = Laser.WorldRotation;

		LaserEndRotation = LaserTarget.WorldRotation;
	}

	UFUNCTION()
	private void Overlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
			Timer::SetTimer(this, n"Delay",DelayStart);
	}

	UFUNCTION()
	void Delay()
	{
		MoveLaser.Play();
	}

	UFUNCTION()
	private void LaserMover(float CurrentValue)
	{
		Laser.SetWorldLocation(Math::Lerp(LaserStart, LaserEnd, CurrentValue));
		Laser.SetWorldRotation(Math::LerpShortestPath(LaserStartRotation, LaserEndRotation, CurrentValue));
	}
};