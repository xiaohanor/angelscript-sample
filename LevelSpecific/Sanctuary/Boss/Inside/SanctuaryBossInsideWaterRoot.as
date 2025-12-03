class ASanctuaryBossInsideWaterRoot : AHazeActor
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

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike IntensityRollTimeLike;
	default IntensityRollTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	float StartRoll;
	float TargetRoll;
	float ConstantRoll;
	float AddedRoll;
	float Intesity = 1.0;
	float ConstantRollMultiplier = 1.0;
	float ConstantRollDegrees = 3.5;
	float OldConstantRoll;
	float TargetConstantRoll;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BodyRotationTimeLike.BindUpdate(this, n"BodyRotationTimeLikeUpdate");
		BodyRotationTimeLike.BindFinished(this, n"BodyRotationTimeLikeFinished");
		ConstantBodyRotationTimeLike.BindUpdate(this, n"ConstantBodyRotationTimeLikeUpdate");
		IntensityRollTimeLike.BindUpdate(this, n"IntensityRollTimeLikeUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasControl())
		{
			float CombinedRoll = (ConstantRoll + AddedRoll) * Intesity;
			FRotator WaterRotation(0.0, 0.0, CombinedRoll);
			SyncedRotationComp.Value = WaterRotation;

			PrintToScreen("ConstantRoll = " + ConstantRoll);
			PrintToScreen("AddedRoll = " + AddedRoll);
			PrintToScreen("ConstantRollDegrees = " + ConstantRollDegrees);

		}

		SetActorRotation(SyncedRotationComp.Value);

		for (auto Player : Game::Players)
		{
			Player.OverrideGravityDirection(-ActorRotation.UpVector, this);
		}

	/*
	//Too much
		if(BodyRotationTimeLike.IsPlaying())
		{
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
			FF.RightMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
			ForceFeedback::PlayWorldForceFeedbackForFrame(FF, ActorLocation, 100000, 150000);
		}*/
	}

	UFUNCTION()
	void Activate()
	{
		if (!HasControl())
			return;

		ConstantBodyRotationTimeLike.SetNewTime(0.5 * 3.5);
		ConstantBodyRotationTimeLike.Play();
	}

	UFUNCTION()
	void SetInitialRotation(float Roll)
	{
		AddedRoll = Roll;
		TargetRoll = AddedRoll;
	}

	UFUNCTION()
	private void IntensityRollTimeLikeUpdate(float CurrentValue)
	{
		Intesity = Math::Lerp(1.0, 0.0, CurrentValue);
	}

	UFUNCTION(BlueprintCallable)
	void StartRotation(float InDuration, float InTargetRoll)
	{
		if (Math::IsNearlyEqual(InTargetRoll, TargetRoll))
			return;

		BodyRotationTimeLike.SetPlayRate(1.0 / InDuration);
		TargetRoll = InTargetRoll;
		StartRoll = Root.WorldRotation.Roll - ConstantRoll;
		BodyRotationTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void BodyRotationTimeLikeUpdate(float CurrentValue)
	{
		AddedRoll = Math::Lerp(StartRoll, TargetRoll, CurrentValue);
		ConstantRollMultiplier = Math::Lerp(1.0, 0.0, CurrentValue);
	}

	UFUNCTION()
	private void BodyRotationTimeLikeFinished()
	{
		ConstantRollMultiplier = 1.0;
		ConstantBodyRotationTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void ConstantBodyRotationTimeLikeUpdate(float CurrentValue)
	{
		ConstantRoll = Math::Lerp(ConstantRollDegrees, -ConstantRollDegrees, CurrentValue * ConstantRollMultiplier);
	}

	UFUNCTION()
	void StopRotation()
	{
		IntensityRollTimeLike.Play();
	}

	UFUNCTION(BlueprintCallable)
	void SetConstantRollValue(float NewConstantRoll)
	{
		OldConstantRoll = ConstantRollDegrees;
		TargetConstantRoll = NewConstantRoll;
		//ConstantRollDegrees = NewConstantRoll;
		QueueComp.Duration(1.0, this, n"BlendConstantRollUpdate");
	}

	UFUNCTION()
	private void BlendConstantRollUpdate(float Alpha)
	{
		ConstantRollDegrees = Math::Lerp(OldConstantRoll, TargetConstantRoll, Alpha);
	}
};