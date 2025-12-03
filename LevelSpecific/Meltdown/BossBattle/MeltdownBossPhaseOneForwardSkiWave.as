class AMeltdownBossPhaseOneForwardSkiWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DisplaceMove;

	UPROPERTY(EditAnywhere)
	float Speed = 10;

	UPROPERTY(EditAnywhere)
	float Lifetime = 10;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(DefaultComponent)
	UBillboardComponent StartLocation;

	UPROPERTY(DefaultComponent)
	UBillboardComponent EndLocation;

	UPROPERTY()
	FVector StartVector;

	UPROPERTY()
	FVector EndVector;

	UPROPERTY(DefaultComponent, Attach = DisplaceMove)
	UMeltdownBossCubeGridDisplacementComponent DisplaceComp;

	UPROPERTY()
	FHazeTimeLike MoveDisplace;
	default MoveDisplace.Duration = 5;
	default MoveDisplace.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);

		StartVector = StartLocation.RelativeLocation;

		EndVector = EndLocation.RelativeLocation;

	}



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorWorldOffset(ActorForwardVector * Speed);
	}

};