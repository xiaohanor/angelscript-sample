class UAnimInstanceSketchBookCrab : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")
	FHazePlaySequenceData EnterArena;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")
	FHazePlaySequenceData CrushText;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Enter")
	FHazePlaySequenceData CrushTextLand;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Burrow")
	FHazePlaySequenceData BurrowEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Burrow")
	FHazePlaySequenceData BurrowChasePlayer;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Burrow")
	FHazePlaySequenceData AnticipateJump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Burrow")
	FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Shoot")
	FHazePlaySequenceData ShootMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Shoot")
	FHazePlaySequenceData ShootLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Shoot")
	FHazePlaySequenceData ShootRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Killed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCrushText;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLand;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBurrow;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int ProjectileLaneIndex;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBurrowComplete;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAnticipateJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShootProjectile;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESketchbookCrabBossSubPhase Phase;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bKilled;

	USketchbookCrabBossComponent CrabComp;
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
		if (CrabComp == nullptr)
		{
			if (HazeOwningActor != nullptr)
				CrabComp = USketchbookCrabBossComponent::Get(HazeOwningActor);
			return;
		}

		Phase = CrabComp.SubPhase;

		bLand = GetAnimBoolParam(n"Land");

		bBurrow = GetAnimBoolParam(n"EnterBurrow");
		bBurrowComplete = GetAnimTrigger(n"BurrowComplete");
		bAnticipateJump = GetAnimTrigger(n"AnticipateJump");
		bJump = GetAnimTrigger(n"Jump");
		bHitThisFrame = GetAnimTrigger(n"TakeDamage");

		bShootProjectile = GetAnimTrigger(n"ShootProjectile");
		if (bShootProjectile)
			ProjectileLaneIndex = GetAnimIntParam(n"ProjectileLaneIndex", true, -1);

		bKilled = Boss.bIsKilled;
		if (bKilled)
			HazeOwningActor.SetActorRotation(FRotator(0, 180, 0));
	}
}