class AMeltdownBossPhaseThreeCrystalRocks : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem CrystalFX;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Crystal;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Ptrigger;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CrystalTarget;
	default CrystalTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default CrystalTarget.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = Crystal)
	UDamageTriggerComponent Damage;

	FVector Start;
	FVector End;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike CrystalErupt;
	default CrystalErupt.Duration = 1.0;
	default CrystalErupt.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CrystalErupt.BindUpdate(this, n"UpdateCrystal");

		Start = Crystal.RelativeLocation;
		End = CrystalTarget.RelativeLocation;

		Ptrigger.OnActorBeginOverlap.AddUFunction(this, n"CrystalStart");

	}

	UFUNCTION()
	private void CrystalStart(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
	//		Niagara::SpawnOneShotNiagaraSystemAtLocation(CrystalFX, ActorLocation);
			CrystalErupt.Play();
	}

	UFUNCTION()
	private void UpdateCrystal(float CurrentValue)
	{
		Crystal.SetRelativeLocation(Math::Lerp(Start, End, CurrentValue));
	}
};