class UAnimInstanceLightWorm : UHazeAnimInstanceBase
{
    
    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData SleepingMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData AttractStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData AttractStartFast;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData AttractMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData TranceStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData TranceMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData TranceStop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData RetreatStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData RetreatMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData SleepingStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Attacking;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Constrained;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData Swing;

	// Custom Variables

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeRuntimeSpline Spline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ALightSeeker LightSeeker;	

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	AMeltdownBossPhaseThreeLightSeeker MeltdownLightSeeker;	

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LightBirdLocation;

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bIsSleeping;

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bIsAttracted;

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bInTrance;

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bIsRetreating;

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bIsSwinging = false;

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bIsGrappling = false;

	UPROPERTY(Transient, BlueprintReadOnly)
	float DownUpGradient = 0.0; // -1 down, 1 up

	UPROPERTY(Transient, BlueprintReadOnly)
	float LeftRightGradient = 0.0; // -1 left, 1 right

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bIsAttacking;

	UPROPERTY(Transient, BlueprintReadOnly)
	bool bIsConstrained;

	UPROPERTY(Transient, BlueprintReadOnly)
	float AttackAlpha;

	UPROPERTY(Transient, BlueprintReadOnly)
	float AttackTime;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LookAtAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditiveAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DistanceOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DistanceToLightBird;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform MeshTransform;

	FVector BirdLoc;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
  		LightSeeker = Cast<ALightSeeker>(HazeOwningActor); 

		MeltdownLightSeeker = Cast<AMeltdownBossPhaseThreeLightSeeker>(HazeOwningActor);
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LightSeeker != nullptr)
			UpdateLightSeeker();	

		if(MeltdownLightSeeker != nullptr)	
			UpdateMeltdownLightSeeker();
	}

    void UpdateMeltdownLightSeeker()
    {
		Spline = MeltdownLightSeeker.RuntimeSpline;
		MeshTransform.SetScale3D(FVector::OneVector * 3);
    }

	UFUNCTION()
	void UpdateLightSeeker()
	{
		auto LightBirdUserComponent = IsValid(Game::Mio) ? ULightBirdUserComponent::Get(Game::Mio) : nullptr;
		if (LightBirdUserComponent == nullptr)
			return;

		FVector BirdLocation = LightBirdUserComponent.Companion.GetActorLocation();
		LightBirdLocation = BirdLocation;
		
		Spline = LightSeeker.RuntimeSpline;
		
		bIsSleeping = LightSeeker.bIsSleeping;
		bIsAttracted = LightSeeker.bIsChasing;
		bInTrance = LightSeeker.bIsInTrance;
		bIsRetreating = LightSeeker.bIsReturning;
		bIsAttacking = LightSeeker.bIsAttacking;
		bIsConstrained = LightSeeker.bIsConstrained;
		bIsSwinging = LightSeeker.bIsSwinging;
		bIsGrappling = LightSeeker.bIsGrappling;
		DownUpGradient = LightSeeker.AnimationDownUpGradient.Value;
		LeftRightGradient = LightSeeker.AnimationLeftRightGradient.Value;

		AttackAlpha = LightSeeker.AttackAlpha;
		AttackTime = LightSeeker.AttackTime;


		LookAtAlpha = Math::Clamp(((((BirdLocation - LightSeeker.Head.WorldLocation).Size()) / 1000 * -1) + 1.5), 0.0, 1.0);

		
		if (!bIsSleeping)
		{
			DistanceToLightBird = (BirdLocation - LightSeeker.Head.WorldLocation).Size();
			DistanceOffset = Math::Clamp((((DistanceToLightBird / 700 * -1) * 150) + 300), 0, 150);
			DistanceOffset *= ((AttackAlpha - 1) * -1);
		}
		else 
		{
			DistanceOffset = 0;
			DistanceToLightBird = 0;
		}
				

		#if EDITOR	

		/*
		Print("bIsGrappling: " + bIsGrappling, 0.f); // Emils Print
		Print("DownUpGradient: " + DownUpGradient, 0.f); // Emils Print
		Print("LeftRightGradient: " + LeftRightGradient, 0.f); // Emils Print
			Print("bInTrance: " + bInTrance, 0.f);
			Print("bIsConstrained: " + bIsConstrained, 0.f); // Emils Print
		Print("LightBirdLocation: " + LightBirdLocation, 0.f); // Emils Print
		Print("bIsSwinging: " + bIsSwinging, 0.f); // Emils Print
		Print("DistanceToLightBird: " + DistanceToLightBird, 0.f);
				Print("bIsConstrained: " + bIsConstrained, 0.f);
			Print("bIsAttracted: " + bIsAttracted, 0.f);
			Print("AttackAlpha: " + AttackAlpha, 0.f);
			Print("(AttackAlpha * -1 - 1): " + Math::Clamp(((AttackAlpha - 1) * 1), 0.0, 1.0), 0);
			Print("DistanceOffset: " + DistanceOffset, 0.f);
			Print("bIsAttacking: " + bIsAttacking, 0.f);
			Print("AttackAlpha: " + AttackAlpha, 0.f);
			Print("AttackTime: " + AttackTime, 0.f);

			Print("LookAtAlpha: " + LookAtAlpha, 0.f);
		*/
		#endif
	}

    
}