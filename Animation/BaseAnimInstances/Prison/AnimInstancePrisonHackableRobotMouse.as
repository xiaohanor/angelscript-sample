class UAnimInstancePrisonHackableRobotMouse : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData StartHack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData UnHacked;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Chew;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FallMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FallStruggle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FallUnHacked;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BlendSpaceValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFallen;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHacked;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIdle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasInput;

	UPlayerMovementComponent MoveComp;

	ARemoteHackableRobotMouse RobotMouse;

	FVector CachedActorLocation;

	float IdleTime;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		RobotMouse = Cast<ARemoteHackableRobotMouse>(HazeOwningActor);
		if (Game::Mio != nullptr)
			MoveComp = UPlayerMovementComponent::Get(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (MoveComp == nullptr)
		{
			if (Game::Mio != nullptr)
				MoveComp = UPlayerMovementComponent::Get(Game::Mio);

			return;
		}

		bHacked = !RobotMouse.bIdling;
		bHasInput = !MoveComp.SyncedLocalSpaceMovementInputForAnimationOnly.IsNearlyZero(0.2);

		bFallen = RobotMouse.bFallen;

		if (DeltaTime > 0)
			BlendSpaceValue = (CachedActorLocation - HazeOwningActor.ActorLocation).SizeSquared() / DeltaTime / 150;

		if (BlendSpaceValue < 0.01)
			IdleTime += DeltaTime;
		else
			IdleTime = 0;

		bIdle = IdleTime > 2;

		CachedActorLocation = HazeOwningActor.ActorLocation;
	}
}