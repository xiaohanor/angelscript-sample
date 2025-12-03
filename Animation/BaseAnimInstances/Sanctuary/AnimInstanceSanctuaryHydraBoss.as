class UAnimInstanceSanctuaryHydraBoss : UHazeAnimInstanceBase
{

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHydraBossArenaAnimData ArenaAnimData;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSkydiveHydraBossAnimData SkydiveAnimData;
    
    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData MhVar2;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData RndMh;


	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData EnterSmash;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")	
    FHazePlaySequenceData TelegraphSmash;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")	
    FHazePlaySequenceData Smash;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ReturnSmash;


	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData EnterFireBreath;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")	
    FHazePlaySequenceData TelegraphFireBreath;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")	
    FHazePlaySequenceData FireBreath;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ReturnFireBreath;


	UPROPERTY(BlueprintReadOnly, Category = "Animations")	
    FHazePlaySequenceData Roar;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")	
    FHazePlaySequenceData RoarStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")	
    FHazePlaySequenceData RoarMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")	
    FHazePlaySequenceData RoarStop;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FHazeRuntimeSpline Spline;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ASanctuaryBossHydraHead HydraHead;


	// Custom variables

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsIdling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringSmash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsTelegraphingSmash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSmashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSmashReturning;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsEnteringFireBreath;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsTelegraphingFireBreath;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFireBreathing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFireBreathReturning;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDecapitated;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int RandomMh;

	// Hydra arena animation datas
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector MioLocation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector ZoeLocation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioFlying;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeFlying;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSubmerging;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEmerging;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGloryKill;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bProjectileAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bRainAttack;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWaveAttack;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AnnoyedAmount = 0.0;

	// ---

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform HeadTargetTransform;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESanctuaryHydraBossPhase BossPhase;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector HeadTargetPosition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HeadTargetRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		HydraHead = Cast<ASanctuaryBossHydraHead>(HazeOwningActor);
		if (HydraHead == nullptr)
			return;

		ArenaAnimData = HydraHead.LocomotionFeature.ArenaAnimData;
		SkydiveAnimData = HydraHead.LocomotionFeature.SkydiveAnimData;
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		RandomMh = 0;

    }


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HydraHead == nullptr)
			return;
		
		Spline = HydraHead.RuntimeSpline;

		bIsEnteringSmash = HydraHead.AnimationData.bIsEnteringSmash;
		bIsTelegraphingSmash = HydraHead.AnimationData.bIsTelegraphingSmash;
		bIsSmashing = HydraHead.AnimationData.bIsSmashing;
		bIsSmashReturning = HydraHead.AnimationData.bIsSmashReturning;

		bIsEnteringFireBreath = HydraHead.AnimationData.bIsEnteringFireBreath;
		bIsTelegraphingFireBreath = HydraHead.AnimationData.bIsTelegraphingFireBreath;
		bIsFireBreathing = HydraHead.AnimationData.bIsFireBreathing;
		bIsFireBreathReturning = HydraHead.AnimationData.bIsFireBreathReturning;

		BossPhase = HydraHead.AnimationData.Phase;

		bDecapitated = HydraHead.AnimationData.bDecapitated;
		bIsIdling = HydraHead.AnimationData.bIsIdling;

		Spline.GetLocationAndRotation(1, HeadTargetPosition, HeadTargetRotation);

		HeadTargetTransform = HydraHead.HeadPivot.WorldTransform;

		#if EDITOR	
		/*
		PrintTrueState("bIsEnteringSmash", bIsEnteringSmash);
		PrintTrueState("bIsTelegraphingSmash", bIsTelegraphingSmash);
		PrintTrueState("bIsSmashing", bIsSmashing);
		PrintTrueState("bIsSmashReturning", bIsSmashReturning);

		PrintTrueState("bIsEnteringFireBreath", bIsEnteringFireBreath);
		PrintTrueState("bIsTelegraphingFireBreath", bIsTelegraphingFireBreath);
		PrintTrueState("bIsFireBreathing", bIsFireBreathing);
		PrintTrueState("bIsFireBreathReturning", bIsFireBreathReturning);

		Print("bIsEnteringSmash: " + bIsEnteringSmash, 0.f); // Emils Print
		Print("bIsTelegraphingSmash: " + bIsTelegraphingSmash, 0.f);
		Print("bIsSmashing: " + bIsSmashing, 0.f);
		Print("bIsSmashReturning: " + bIsSmashReturning, 0.f); // Emils Print
		
		Print("bIsEnteringFireBreath: " + bIsEnteringFireBreath, 0.f); // Emils Print
		Print("bIsTelegraphingFireBreath: " + bIsTelegraphingFireBreath, 0.f);
		Print("bIsFireBreathing: " + bIsFireBreathing, 0.f);
		Print("bIsFireBreathReturning: " + bIsFireBreathReturning, 0.f); // Emils Print
		
		Print("bDecapitated: " + bDecapitated, 0.f);
		Print("bIsIdling: " + bIsIdling, 0.f);

		Debug::DrawDebugPoint(HeadTargetPosition, 50.0, bRenderInForground = true);
		*/
		#endif
    }

	
    UFUNCTION()
    void AnimNotify_PickRandomMh()
    {
        RandomMh = Math::RandRange(0, 1);
    }

	void PrintTrueState(FString Text, bool ActiveState)
	{
		if (ActiveState)
			PrintToScreenScaled(Text + ": " + ActiveState, 0.f, Scale = 3.f); // Emils Print
	}
}