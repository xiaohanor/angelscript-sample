class UAnimInstanceMoonMarketMole : UHazeAnimInstanceBase
{
	/* ----------SEQUENCES---------- */

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData IdleMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData RandomConversation;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WalkMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ThunderReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RainReactionEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RainReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData RainReactionExit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData CandyHitReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData TrumpetReaction;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FireworkReaction;

	/* ----------VARIABLES---------- */

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsTalking;

	UPROPERTY(BlueprintReadOnly)
	AMoonMarketMole Mole;

	/* ----------REACTIONS---------- */

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsReacting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsThunderStruck;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRainedOn;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsCandyHit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsTrumpetHonkedAt;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFireworkHit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLookAtEnabled;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bReactedRecently;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LookAtLocation;

	float LastReactionTime = 0;
	float PollLookAtTargetTime = 0;

	AHazeActor LookAtTarget;

	const FVector LOOK_AT_OFFSET = FVector(0, 0, 50);

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		Mole = Cast<AMoonMarketMole>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Mole == nullptr)
			return;

		LastReactionTime = Math::Max(LastReactionTime, Mole.ThunderStruckComp.LastRainTime);
		bIsThunderStruck = GetAnimTrigger(n"ThunderStruck");
		bIsCandyHit = GetAnimTrigger(n"CandyHit");
		bIsFireworkHit = GetAnimTrigger(n"FireworkHit");
		bIsTrumpetHonkedAt = GetAnimTrigger(n"HonkedAt");
		bIsRainedOn = Mole.ThunderStruckComp.WasRainedOnRecently();

		bIsReacting = IsReacting();
		if (bIsReacting)
			LastReactionTime = Time::GameTimeSeconds;

		bReactedRecently = false;
		if (Time::GetGameTimeSince(LastReactionTime) < 1.5)
			bReactedRecently = true;

		BlendspaceValues.Y = Mole.MoveComp.Velocity.VectorPlaneProject(FVector::UpVector).Size();
		bIsMoving = BlendspaceValues.Y > 5 && !Mole.WalkComp.bIdling;
		bIsTalking = !bReactedRecently && ((Mole.WalkComp.bIdling && Mole.WalkComp.PreviousIdlePoint.bTalkingPoint) || Mole.bAlwaysTalking);

		// Look At
		if (!Mole.bAlwaysTalking && !bIsReacting)
		{
			PollLookAtTargetTime -= DeltaTime;
			if (PollLookAtTargetTime <= 0 && Game::Mio != nullptr)
			{
				PollLookAtTargetTime = Math::RandRange(1, 3);

				const FVector MioDelta = (Game::Mio.ActorLocation - HazeOwningActor.ActorLocation);
				const FVector ZoeDelta = (Game::Zoe.ActorLocation - HazeOwningActor.ActorLocation);
				const float MioDistanceSquared = MioDelta.SizeSquared();
				const float ZoeDistanceSquared = ZoeDelta.SizeSquared();
				if (MioDistanceSquared < ZoeDistanceSquared && MioDelta.DotProduct(HazeOwningActor.ActorForwardVector) > 0)
				{
					if (MioDistanceSquared < 1000000)
						LookAtTarget = Game::Mio;
					else
						LookAtTarget = nullptr;
				}
				else if (ZoeDelta.DotProduct(HazeOwningActor.ActorForwardVector) > 0)
				{
					if (ZoeDistanceSquared < 1000000)
						LookAtTarget = Game::Zoe;
					else
						LookAtTarget = nullptr;
				}
				else
					LookAtTarget = nullptr;

				if (!bLookAtEnabled && LookAtTarget != nullptr)
					LookAtLocation = LookAtTarget.ActorLocation + LOOK_AT_OFFSET;

				bLookAtEnabled = LookAtTarget != nullptr;
			}

			if (bLookAtEnabled)
				LookAtLocation = Math::VInterpTo(LookAtLocation, LookAtTarget.ActorLocation + LOOK_AT_OFFSET, DeltaTime, 3);
		}
	}

	bool IsReacting()
	{
		if (bIsThunderStruck || bIsCandyHit || bIsTrumpetHonkedAt || bIsFireworkHit)
			return true;

		return false;
	}
}