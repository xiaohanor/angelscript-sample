class AMeltdownBossPhaseThreeLaserPivot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PivotCube;
	default PivotCube.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.DamageAmount = 0.5;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Ptrigger;

	FHazeTimeLike PivotLike;
	default PivotLike.Duration = 2.0;
	default PivotLike.UseSmoothCurveZeroToOne(); 

	FRotator Startrotation;
	FRotator Endrotation = FRotator(0,-90,0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Startrotation = ActorRotation;

		PivotLike.BindUpdate(this, n"Rotate");

		Ptrigger.OnActorBeginOverlap.AddUFunction(this, n"StartRotating");

		DamageTrigger.OnPlayerDamagedByTrigger.AddUFunction(this, n"PlayerHit");
		
	}

	UFUNCTION()
	private void PlayerHit(AHazePlayerCharacter Player)
	{
		auto SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
		SkydiveComp.RequestHitReaction(ActorLocation);
	}

	UFUNCTION()
	private void StartRotating(AActor OverlappedActor, AActor OtherActor)
	{
		PivotLike.Play();
	}

	UFUNCTION()
	private void Rotate(float CurrentValue)
	{
		SetActorRotation(Math::LerpShortestPath(Startrotation, Endrotation, CurrentValue));
	}
};