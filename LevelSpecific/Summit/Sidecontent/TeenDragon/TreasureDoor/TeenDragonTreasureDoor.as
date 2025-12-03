class ATeenDragonTreasureDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RDoorRoot;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LDoorRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CoinPilesRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent CoinSystem1;
	default CoinSystem1.SetAutoActivate(false);
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent CoinSystem2;
	default CoinSystem2.SetAutoActivate(false);
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent CoinSystem3;
	default CoinSystem3.SetAutoActivate(false);

	float System1Time = 1.5;
	float System2Time = 2.5;
	float System3Time = 3.5;

	UPROPERTY(EditInstanceOnly)
	ANightQueenMetal Metal;
	
	FVector CoinPileStartLoc;
	FVector CoinPileTargetLoc;

	float DoorRotateAmount = 80.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		CoinPileTargetLoc = CoinPilesRoot.RelativeLocation;
		CoinPileStartLoc = FVector(0, 0, 0);
		CoinPilesRoot.RelativeLocation = CoinPileStartLoc;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RDoorRoot.RelativeRotation = Math::RInterpTo(RDoorRoot.RelativeRotation, FRotator(0, DoorRotateAmount, 0), DeltaSeconds, 0.8);
		LDoorRoot.RelativeRotation = Math::RInterpTo(LDoorRoot.RelativeRotation, FRotator(0, -DoorRotateAmount, 0), DeltaSeconds, 0.8);

		CoinPilesRoot.RelativeLocation = Math::VInterpTo(CoinPilesRoot.RelativeLocation, CoinPileTargetLoc, DeltaSeconds, 0.75);

		if (System1Time > 0.0)
		{
			System1Time -= DeltaSeconds;

			if (System1Time <= 0.0)
				CoinSystem1.Deactivate();
		}

		if (System2Time > 0.0)
		{
			System2Time -= DeltaSeconds;

			if (System2Time <= 0.0)
				CoinSystem2.Deactivate();
		}

		if (System3Time > 0.0)
		{
			System3Time -= DeltaSeconds;

			if (System3Time <= 0.0)
				CoinSystem3.Deactivate();
		}
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		CoinSystem1.Activate();
		CoinSystem2.Activate();
		CoinSystem3.Activate();
		SetActorTickEnabled(true);
	}
};