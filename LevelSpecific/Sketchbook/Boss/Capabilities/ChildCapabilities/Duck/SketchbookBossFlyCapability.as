class USketchbookBossFlyCapability : USketchbookDuckBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	bool bShouldLand = false;

	AHazePlayerCharacter TargetPlayer;

	FVector TargetLocation;

	FVector BaseLocation;

	USketchbookBossJumpComponent JumpComp;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JumpComp = USketchbookBossJumpComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DuckComp.SubPhase != ESketchbookDuckBossSubPhase::Flying)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bShouldLand)
			return true;

		if(TargetLocation.Distance(BaseLocation) <= KINDA_SMALL_NUMBER)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Boss.CurrentTargetPlayer;
		bShouldLand = false;
		DuckComp.bCanDropEgg = true;
		BaseLocation = Owner.ActorLocation;
		//Start flying to whichever side is furthest away
		SetNewTargetPosition();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.LandingLocation = Owner.ActorLocation - FVector::UpVector * DuckComp.HoverHeight;
		JumpComp.LandingLocation.Z = Boss.ArenaFloorZ;
		DuckComp.CurrentLaps++;
		DuckComp.bCanDropEgg = false;
		Boss.Idle(0.5);
		// Boss.RotateTowards(FRotator(0,180,0).Quaternion());
		if(bShouldLand)
		{
			DuckComp.SubPhase = ESketchbookDuckBossSubPhase::Land;
			// Boss.RotateTowards(FQuat(0,0,0,1));
			DuckComp.CurrentLaps = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bShouldLand)
			return;
		
		BaseLocation = Math::VInterpConstantTo(BaseLocation, TargetLocation, DeltaTime, DuckComp.FlySpeed);
		FVector NewLocation = BaseLocation + FVector::UpVector * Math::Sin(ActiveDuration * DuckComp.BobSpeed) * DuckComp.BobStrength;

		if(DuckComp.CurrentLaps >= DuckComp.LapsPerAttack)
		{
			if(Math::Abs(TargetPlayer.ActorLocation.Y - Owner.ActorLocation.Y) < 10)
			{
				bShouldLand = true;
			}
			else 
			{
				float DistOutsideArena = Math::Abs(TargetPlayer.ActorLocation.Y - Boss.StartLocation.Y) - SketchbookBoss::Settings::ArenaHalfWidth;
				float DistToPlayer = Math::Abs(TargetPlayer.ActorLocation.Y - Owner.ActorLocation.Y);
				if(DistOutsideArena >= 0 && DistToPlayer <= DistOutsideArena)
					bShouldLand = true;
			}
		}

		Owner.SetActorLocation(NewLocation);
	}

	void SetNewTargetPosition()
	{
		float LeftSide = Boss.GetArenaLeftSide();
		float RightSide = Boss.GetArenaRightSide();

		DuckComp.bIsGoingLeft = Math::Abs(LeftSide - Owner.ActorLocation.Y) > Math::Abs(RightSide - Owner.ActorLocation.Y);

		TargetLocation = FVector(0, 0, Boss.ArenaFloorZ + DuckComp.HoverHeight);

		if(DuckComp.bIsGoingLeft)
			TargetLocation.Y = Boss.GetArenaLeftSide();
		else
			TargetLocation.Y = Boss.GetArenaRightSide();

		// const float TargetYaw = DuckComp.bIsGoingLeft ? DuckComp.FlyingYaw : -DuckComp.FlyingYaw;
		// FQuat TargetRotation = FQuat::MakeFromEuler(FVector::UpVector * TargetYaw);
		// Boss.RotateTowards(TargetRotation);
	}
};