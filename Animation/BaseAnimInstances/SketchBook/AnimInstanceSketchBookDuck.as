class UAnimInstanceSketchBookDuck : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Land;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData SoftLand;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|SquareJump")
	FHazePlaySequenceData SquareJumpUp;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|SquareJump")
	FHazePlaySequenceData SquareJumpSideWay;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|SquareJump")
	FHazePlaySequenceData SquareJumpDown;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|SquareJump")
	FHazePlaySequenceData SquareJumpLand;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|DropEgg")
	FHazePlaySequenceData DropEggEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|DropEgg")
	FHazePlaySequenceData DropEggMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|DropEgg")
	FHazePlaySequenceData DropEggAdditive;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|DropEgg")
	FHazePlaySequenceData DropEggExit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Killed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bForceUpdatePose;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLand;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SquareJump")
	bool bSquareJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "SquareJump")
	ESketchbookSquareJumpPhase SquareJumpPhase;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "DropEgg")
	FRotator BirdRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "DropEgg")
	bool bDropEgg;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartFlying;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartLanding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bKilled;

	USketchbookDuckBossComponent DuckComp;
	ASketchbookBoss Boss;

	FVector CachedActorLocation;

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
		if (DuckComp == nullptr)
		{
			if (HazeOwningActor != nullptr)
				DuckComp = USketchbookDuckBossComponent::Get(HazeOwningActor);
			return;
		}

		bForceUpdatePose = GetAnimTrigger(n"UpdatePose");

		bJump = GetAnimTrigger(n"Jump");
		bLand = GetAnimTrigger(n"Land");

		bHitThisFrame = GetAnimTrigger(n"TakeDamage");

		bStartLanding = GetAnimTrigger(n"StartLanding");
		bStartFlying = GetAnimBoolParam(n"StartFlying");

		bSquareJump = GetAnimTrigger(n"SquareJump");
		const int SquareJumpPhaseInt = GetAnimIntParam(n"SquareJumpPhase", true, -1);
		if (SquareJumpPhaseInt >= 0)
			SquareJumpPhase = ESketchbookSquareJumpPhase(SquareJumpPhaseInt);

		const FVector DeltaMove = (Boss.ActorLocation - CachedActorLocation);
		const float MoveDir = Math::Sign(DeltaMove.Y);

		BirdRotation.Roll = -5 * MoveDir;

		bDropEgg = GetAnimTrigger(n"DropProjectile");

		CachedActorLocation = Boss.ActorLocation;

		bKilled = Boss.bIsKilled;
	}
}