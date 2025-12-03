class UAnimInstanceMoonMarketCodyDoor : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FMoonMarketHidingGhostAnimations Animations;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHiding;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLookAtEnabled;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LookAtLocation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CloseDoorSpeed = 1;

	AMoonMarketHidingGhost HidingCody;


	AHazeActor LookAtTarget;
	float PollLookAtTargetTime;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		HidingCody = Cast<AMoonMarketHidingGhost>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HidingCody == nullptr)
			return;

		bIsHiding = HidingCody.bIsClosed;
		Animations = HidingCody.bIsCody ? HidingCody.CodyAnims : HidingCody.MayAnims;
		CloseDoorSpeed = HidingCody.bFireworkInRange ? 2.5 : 1;
		HidingCody.UpdateMesh();

		if (!bIsHiding)
		{
			PollLookAtTargetTime -= DeltaTime;
			if (PollLookAtTargetTime <= 0 && Game::Mio != nullptr)
			{
				UpdateLookAtTarget();
				PollLookAtTargetTime = Math::RandRange(1, 4);
			}

			if (bLookAtEnabled)
				LookAtLocation = Math::VInterpTo(LookAtLocation, GetLookAtLocation(), DeltaTime, 3);
		}
	}

	void UpdateLookAtTarget()
	{
		const float MioDistanceSquared = (Game::Mio.ActorLocation - HazeOwningActor.ActorLocation).SizeSquared();
		const float ZoeDistanceSquared = (Game::Zoe.ActorLocation - HazeOwningActor.ActorLocation).SizeSquared();
		if (MioDistanceSquared < ZoeDistanceSquared)
		{
			if (MioDistanceSquared < 10000000)
				LookAtTarget = Game::Mio;
			else
				LookAtTarget = nullptr;
		}
		else
		{
			if (ZoeDistanceSquared < 10000000)
				LookAtTarget = Game::Zoe;
			else
				LookAtTarget = nullptr;
		}

		if (!bLookAtEnabled && LookAtTarget != nullptr)
			LookAtLocation = GetLookAtLocation();

		bLookAtEnabled = LookAtTarget != nullptr;
	}

	const FVector GetLookAtLocation()
	{
		return LookAtTarget.ActorLocation + FVector(0, 0, 100);
	}
}