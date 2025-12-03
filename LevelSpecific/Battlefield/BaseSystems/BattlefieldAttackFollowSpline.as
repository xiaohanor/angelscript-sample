event void FOnBattlefieldAttackFollowStarted(FVector EndPoint);
event void FOnBattlefieldAttackFollowEnded();

class ABattlefieldAttackFollowSpline : AHazeActor
{
	UPROPERTY()
	FOnBattlefieldAttackFollowStarted OnBattlefieldAttackFollowStarted;
	
	UPROPERTY()
	FOnBattlefieldAttackFollowEnded OnBattlefieldAttackFollowEnded;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif


	UPROPERTY(EditAnywhere)
	TArray<ASplineActor> AlternatingSplines;

	UPROPERTY(EditAnywhere)
	float SplinePositionMoveSpeed = 12000.0;

	UPROPERTY(EditAnywhere)
	bool bAutoAttack = true;

	UPROPERTY(EditAnywhere)
	bool bLooping = true;

	UPROPERTY(EditAnywhere)
	float WaitDuration = 1.0;

	UBattlefieldAttackComponent AttackComp;
	
	int SplineIndex;
	int AllowedRuns;

	float WaitTime;
	float CurrentSplineDist;

	bool bReachedSplineEnd;
	bool bMakingRun;
	bool bFiniteRunsAllowed;

	FVector Location;
	FVector Direction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bAutoAttack)
			SetActorTickEnabled(false);

		AttackComp = UBattlefieldAttackComponent::Get(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < WaitTime)
			return;
		else if (!bMakingRun)
			MakeSplineRun();

		Location = AlternatingSplines[SplineIndex].Spline.GetWorldLocationAtSplineDistance(CurrentSplineDist);
		Direction = (Location - AttackComp.WorldLocation).GetSafeNormal();

		CurrentSplineDist += SplinePositionMoveSpeed * DeltaSeconds;
		CurrentSplineDist = Math::Clamp(CurrentSplineDist, 0.0, AlternatingSplines[SplineIndex].Spline.SplineLength);

		if (CurrentSplineDist == AlternatingSplines[SplineIndex].Spline.SplineLength)
		{
			bMakingRun = false;
			WaitTime = Time::GameTimeSeconds + WaitDuration;

			if (!bAutoAttack && !bLooping)
				SetActorTickEnabled(false);

			if (bFiniteRunsAllowed && AllowedRuns == 0)
			{
				bFiniteRunsAllowed = false;
				SetActorTickEnabled(false);
			}

			OnBattlefieldAttackFollowEnded.Broadcast();
		}
	}

	void MakeSplineRun()
	{
		CurrentSplineDist = 0.0;
		SplineIndex++;
		AllowedRuns--;

		AllowedRuns = Math::Clamp(AllowedRuns, 0, 100);

		if (SplineIndex >= AlternatingSplines.Num())
			SplineIndex = 0;

		bMakingRun = true;

		Location = AlternatingSplines[SplineIndex].Spline.GetWorldLocationAtSplineDistance(CurrentSplineDist);
		OnBattlefieldAttackFollowStarted.Broadcast(Location);
	}

	UFUNCTION()
	void ActivateSpecificSplineRun(int CurrentIndex = 0)
	{
		SetActorTickEnabled(true);

		CurrentSplineDist = 0.0;
		SplineIndex = CurrentIndex;
		bMakingRun = true;

		Location = AlternatingSplines[SplineIndex].Spline.GetWorldLocationAtSplineDistance(CurrentSplineDist);
		OnBattlefieldAttackFollowStarted.Broadcast(Location);
	}

	UFUNCTION()
	void ActivateAttackRun(int MaxAllowedRuns = -1)
	{
		if (MaxAllowedRuns > 0)
		{
			bFiniteRunsAllowed = true;
			AllowedRuns = MaxAllowedRuns;
		}
		SetActorTickEnabled(true);
	}

	float GetAlphaAlongSplineProgress()
	{
		if (CurrentSplineDist == 0.0)
			return 0.0;

		return CurrentSplineDist / AlternatingSplines[SplineIndex].Spline.SplineLength;
	}
}

class ABattlefieldAttackProjectileFollowSpline : ABattlefieldAttackFollowSpline
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBattlefieldProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UBattlefieldProjectileFollowSplineComponent ProjectileFollowSplineComp;
}

class ABattlefieldAttackLaserFollowSpline : ABattlefieldAttackFollowSpline
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBattlefieldLaserComponent LaserComp;

	UPROPERTY(DefaultComponent)
	UBattlefieldLaserFollowSplineComponent LaserFollowSplineComp;
}