class ASanctuaryWellBrokenWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BottomPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TopPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	float RotationAmount = 10.0;

	UPROPERTY(EditAnywhere)
	float BulgeDelay = 0.1;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryWellBrokenWall LinkedWall;

	UPROPERTY(EditInstanceOnly)
	bool bDontBulge = false;

	FHazeTimeLike BulgeTimeLike;
	default BulgeTimeLike.UseLinearCurveZeroToOne();
	default BulgeTimeLike.Duration = 0.25;

	float CurrentRotation = 0.0;
	float NewRotation = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BulgeTimeLike.BindUpdate(this, n"BulgeTimeLikeUpdate");
	}

	UFUNCTION()
	void Bulge()
	{
		CurrentRotation = NewRotation;
		NewRotation = CurrentRotation + RotationAmount;
		VFXComp.Activate(true);

		if (!bDontBulge)
			BulgeTimeLike.PlayFromStart();

		for (auto Player : Game::GetPlayers())
		{
			FVector ToPlayerVector = Player.ActorCenterLocation - VFXComp.WorldLocation;

			if (ToPlayerVector.Size() < 850.0)
			{
				FStumble Stumble;
				Stumble.Move = ToPlayerVector.GetSafeNormal() * 300.0 * FVector(1.0, 1.0, 0.0);
				Stumble.Duration = 0.5;
				
				//Player.ApplyStumble(Stumble);
			}
		}

		if (LinkedWall != nullptr)
			Timer::SetTimer(LinkedWall, n"Bulge", BulgeDelay);
	}

	UFUNCTION()
	private void BulgeTimeLikeUpdate(float CurrentValue)
	{
		TopPivotComp.SetRelativeRotation(FRotator(Math::Lerp(CurrentRotation, NewRotation, CurrentValue), 0.0, 0.0));
		BottomPivotComp.SetRelativeRotation(FRotator(Math::Lerp(-CurrentRotation, -NewRotation, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION(BlueprintCallable)
	void RemoveWallCollision()
	{
		AddActorCollisionBlock(this);
	}
};