event void FOnSlamsFinished();

class AMeltdownBossPhaseTwoTridentSlam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Trident;

	UPROPERTY(DefaultComponent , Attach = Trident)
	UBillboardComponent SpawnLeft;

	UPROPERTY(DefaultComponent, Attach = Trident)
	UBillboardComponent SpawnMiddle;

	UPROPERTY(DefaultComponent, Attach = Trident)
	UBillboardComponent SpawnRight;

	UPROPERTY()
	int SlamPosition;

	UPROPERTY()
	FVector StartPosition;
	UPROPERTY()
	FRotator StartRotation;

	UPROPERTY()
	FVector TargetPosition;
	UPROPERTY()
	FRotator TargetRotation;

	UPROPERTY(EditAnywhere)
	AScenepointActor Position01;

	UPROPERTY(EditAnywhere)
	AScenepointActor Position02;

	UPROPERTY(EditAnywhere)
	AScenepointActor Position03;

	UPROPERTY()
	FOnSlamsFinished SlamsFinished;

	FHazeTimeLike MoveTrident;
	default MoveTrident.Duration = 0.2;
	default MoveTrident.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		MoveTrident.BindUpdate(this, n"UpdateTrident");
		MoveTrident.BindFinished(this, n"FinishedTrident");
	}

	UFUNCTION()
	private void UpdateTrident(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(StartPosition,TargetPosition, CurrentValue));
		SetActorRotation(Math::LerpShortestPath(StartRotation, TargetRotation, CurrentValue));
	}

	UFUNCTION()
	private void FinishedTrident()
	{
		DoneMoving();
	}

	UFUNCTION(BlueprintEvent)
	void DoneMoving()
	{

	}

	UFUNCTION(BlueprintCallable)
	void SetNextMoveLocation()
	{
		switch (SlamPosition)
		{
		case 0 : 
			StartPosition = Position01.ActorLocation;
			StartRotation = Position01.ActorRotation;
			TargetPosition = Position02.ActorLocation;
			TargetRotation = Position02.ActorRotation;
			TridentMove();
			SlamPosition = 1;
			break;
		case 1 :
			StartPosition = Position02.ActorLocation;
			StartRotation = Position02.ActorRotation;
			TargetPosition = Position03.ActorLocation;
			TargetRotation = Position03.ActorRotation;
			TridentMove();
			SlamPosition = 2;
			break;
		case 2 : 
			StartPosition = Position03.ActorLocation;
			StartRotation = Position03.ActorRotation;
			TargetPosition = Position01.ActorLocation;
			TargetRotation = Position01.ActorRotation;
			TridentMove();
			SlamPosition = 3;
			break;
		case 3 :
			FinishedSlamming();
			SlamPosition = 0;
			break;
		}
	}


	UFUNCTION()
	void TridentMove()
	{
		MoveTrident.PlayFromStart();
	}

	UFUNCTION(BlueprintCallable)
	void StartSlam()
	{
		if (IsActorDisabled())
			RemoveActorDisable(this);
		
		SlamEvent();
	}

	UFUNCTION(BlueprintCallable)
	void FinishedSlamming()
	{
		SlamsFinished.Broadcast();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void SlamEvent()
	{}
	
};