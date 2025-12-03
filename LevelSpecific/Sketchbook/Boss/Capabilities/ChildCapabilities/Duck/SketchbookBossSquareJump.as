enum ESketchbookSquareJumpPhase
{
	Up,
	Sideways,
	Down,
	Done
}

class USketchbookBossSquareJumpCapability : USketchbookDuckBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	FVector TargetLocation;
	FVector StartLocation;

	USketchbookBossJumpComponent JumpComp;

	ESketchbookSquareJumpPhase CurrentMove;

	float JumpDownStartTime;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JumpComp = USketchbookBossJumpComponent::Get(Owner);
		JumpComp.LandingLocation = Owner.ActorLocation;
		JumpComp.LandingLocation.Z = Boss.ArenaFloorZ;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.GetPhase() != ESketchbookBossPhase::Jump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CurrentMove == ESketchbookSquareJumpPhase::Done)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Always target closest player first
		if(JumpComp.JumpsInRow == 0 && Boss.CurrentTargetPlayer == nullptr)
			Boss.CurrentTargetPlayer = Game::GetClosestPlayer(Boss.ActorLocation);
		else
			Boss.CurrentTargetPlayer = Game::GetOtherPlayer(Boss.CurrentTargetPlayer.Player);

		if(Boss.CurrentTargetPlayer.IsPlayerDead())
			Boss.CurrentTargetPlayer = Game::GetOtherPlayer(Boss.CurrentTargetPlayer.Player);
		
		StartLocation = Boss.ActorLocation;
		CurrentMove = ESketchbookSquareJumpPhase::Up;
		TargetLocation = Boss.CurrentTargetPlayer.ActorLocation;
		TargetLocation.Z = Boss.ArenaFloorZ;

		JumpComp.JumpsInRow++;

		// if(TargetLocation.Y < Owner.ActorLocation.Y)
		// 	Boss.RotateTowards(FQuat::MakeFromEuler(FVector::UpVector * JumpComp.JumpingYaw));
		// else if(TargetLocation.Y > Owner.ActorLocation.Y)
		// 	Boss.RotateTowards(FQuat::MakeFromEuler(FVector::UpVector * -JumpComp.JumpingYaw));
		// else
		// Boss.RotateTowards(FQuat(0,0,0,1));
		
		Boss.Mesh.SetAnimTrigger(n"SquareJump");

		USketchbookBossEffectEventHandler::Trigger_OnJump(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(JumpComp.JumpsInRow >= JumpComp.JumpsToDo)
		{
			Boss.Idle(JumpComp.WaitAfterJumpDuration);
			Boss.StartMainAttackSequence();
			JumpComp.JumpsInRow = 0;
		}
		
		FVector FixedLocation = Owner.ActorLocation;
		FixedLocation.Z = Boss.ArenaFloorZ;
		Owner.SetActorLocation(FixedLocation);

		Boss.Idle(JumpComp.WaitAfterJumpDuration);	
		USketchbookBossEffectEventHandler::Trigger_OnLand(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector CurrentTargetLocation = GetCurrentTargetLocation();
		const float Speed = JumpComp.JumpSpeed;

		FVector NewLocation;
		if(CurrentMove == ESketchbookSquareJumpPhase::Down)
			NewLocation = TargetLocation + FVector::UpVector * JumpComp.JumpHeight * DuckComp.JumpCurve.GetFloatValue(Time::GetGameTimeSince(JumpDownStartTime));
		else
			NewLocation = Math::VInterpConstantTo(Owner.ActorLocation, CurrentTargetLocation, DeltaTime, Speed);
		
		Owner.SetActorLocation(NewLocation);

		CheckTargetReached(CurrentTargetLocation);

		Boss.Mesh.SetAnimIntParam(n"SquareJumpPhase", int(CurrentMove));
	}

	const FVector GetCurrentTargetLocation() const
	{
		if(CurrentMove == ESketchbookSquareJumpPhase::Up)
			return StartLocation + FVector::UpVector * JumpComp.JumpHeight;

		if(CurrentMove == ESketchbookSquareJumpPhase::Sideways)
			return TargetLocation + FVector::UpVector * JumpComp.JumpHeight;

		return TargetLocation;
	}
	
	void CheckTargetReached(FVector CurrentTargetLocation)
	{
		if(Boss.ActorLocation.Distance(CurrentTargetLocation) <= KINDA_SMALL_NUMBER)
		{
			if(CurrentMove == ESketchbookSquareJumpPhase::Up)
				CurrentMove = ESketchbookSquareJumpPhase::Sideways;

			else if(CurrentMove == ESketchbookSquareJumpPhase::Sideways)
			{
				JumpDownStartTime = Time::GameTimeSeconds;
				USketchbookBossEffectEventHandler::Trigger_OnJump(Boss);
				CurrentMove = ESketchbookSquareJumpPhase::Down;
			}

			else if(CurrentMove == ESketchbookSquareJumpPhase::Down)
				CurrentMove = ESketchbookSquareJumpPhase::Done;
		}
	}
};