class UAnimInstanceLightBirdMegaCompanion : UAnimInstanceAIBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Intro")
	FHazePlaySequenceData IntroStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Intro")
	FHazePlaySequenceData IntroReachPlayer;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData HoverMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlaySequenceData StartFly;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlaySequenceData StopFly;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData FlyMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData FlapMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlaySequenceData DashFlap;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData DiveMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Fly")
	FHazePlayBlendSpaceData BankingAdditive;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData LaunchStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData Launch;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData LanternStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Actions")
	FHazePlaySequenceData LanternMh;

	// Custom Variables

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFollowing;

	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	bool bShouldGlide = false;

	UPROPERTY()
	float GlideBlendValue = 0;

	UPROPERTY()
	float MegaPlayRate = 0.5;

	FTimerHandle GlideTimer;

	FVector LastLocation;
	FVector FakeVelocity;

	// On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		if (HazeOwningActor == nullptr)
			return;

		// Mega companion does not get proper actor velocity, calculate speeds here instead
		if (LastLocation.Size() > KINDA_SMALL_NUMBER)
		{
			FVector DeltaMove = HazeOwningActor.ActorLocation - LastLocation;
			FakeVelocity = DeltaMove / DeltaTime;
		}

		{
			// Debug::DrawDebugString(HazeOwningActor.ActorLocation, " " + FakeVelocity);
			SpeedForward = FakeVelocity.DotProduct(HazeOwningActor.ActorForwardVector);		
			SpeedRight = FakeVelocity.DotProduct(HazeOwningActor.ActorRightVector);
			SpeedUp = FakeVelocity.DotProduct(HazeOwningActor.ActorUpVector);

			// Scale speed related stuff
			SpeedForward *= 0.1;
			SpeedRight *= 0.1;
			SpeedUp *= 0.1;
		}
		LastLocation = HazeOwningActor.ActorLocation;

		Velocity.X = SpeedRight;
		Velocity.Y = SpeedForward;
		Velocity.Z = SpeedUp;

		bIsFollowing = true;
		
	}

	UFUNCTION()
	void AnimNotify_EnterFlyState()
	{
		GlideBlendValue = 0;
		float RndGlideTimer = Math::RandRange(3.0, 10.0);
		GlideTimer = Timer::SetTimer(this, n"ShouldGlide", RndGlideTimer);
	}

	UFUNCTION()
	void AnimNotify_LeftFlyState()
	{
		GlideTimer.ClearTimer();
	}

	UFUNCTION()
	void ShouldGlide()
	{
		GlideBlendValue = 1;
		GlideTimer = Timer::SetTimer(this, n"AnimNotify_EnterFlyState", Math::RandRange(1.0, 3.0));
	}
}