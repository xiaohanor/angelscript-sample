class UAnimInstanceSketchBookDemon : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Land;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData GroundToMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Killed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLand;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFly;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bForceUpdate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bKilled;

	ESketchbookDemonBossSubPhase Phase;

	USketchbookDemonBossComponent DemonComp;
	ASketchbookBoss Boss;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Boss = Cast<ASketchbookBoss>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (DemonComp == nullptr)
		{
			if (HazeOwningActor != nullptr)
				DemonComp = USketchbookDemonBossComponent::Get(HazeOwningActor);
			return;
		}

		Phase = DemonComp.SubPhase;

		bJump = GetAnimTrigger(n"Jump");
		bLand = GetAnimTrigger(n"Land");
		bFly = GetAnimTrigger(n"Fly");

		bForceUpdate = GetAnimTrigger(n"UpdatePose");

		bHitThisFrame = GetAnimTrigger(n"TakeDamage");

		if (bJump)
			bLand = false;

		bKilled = Boss.bIsKilled;
		if (bKilled)
			HazeOwningActor.SetActorRotation(FRotator(0, 180, 0));
	}
}