class ASanctuaryBossInsideBodyRoot : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotationComp;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike BodyRotationTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike ConstantBodyRotationTimeLike;

	float StartRoll;
	float TargetRoll;
	float ConstantRoll;
	float AddedRoll;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BodyRotationTimeLike.BindUpdate(this, n"BodyRotationTimeLikeUpdate");
		ConstantBodyRotationTimeLike.BindUpdate(this, n"ConstantBodyRotationTimeLikeUpdate");
	}

	UFUNCTION()
	void Activate()
	{
		if (!HasControl())
			return;

		ConstantBodyRotationTimeLike.Play();
	}

	UFUNCTION(BlueprintCallable)
	void StartRotation(float InDuration, float InTargetRoll)
	{
		BodyRotationTimeLike.SetPlayRate(1.0 / InDuration);
		TargetRoll = InTargetRoll;
		StartRoll = Root.WorldRotation.Roll - ConstantRoll;
		BodyRotationTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void BodyRotationTimeLikeUpdate(float Alpha)
	{
		AddedRoll = Math::Lerp(StartRoll, TargetRoll, Alpha);
	}

	UFUNCTION()
	void ConstantBodyRotationTimeLikeUpdate(float Alpha)
	{
		ConstantRoll = Math::Lerp(-2.5, 2.5, Alpha);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasControl())
		{
			FRotator BodyRotation(0.0, 0.0, ConstantRoll + AddedRoll);
			SyncedRotationComp.Value = BodyRotation;
		}

		SetActorRotation(SyncedRotationComp.Value);
	}
};