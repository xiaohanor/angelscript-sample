class USketchbookBossTrajectoryJumpCapability : USketchbookBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	FVector TargetLocation;

	USketchbookBossJumpComponent JumpComp;

	FTraversalTrajectory JumpTrajectory;

	float LaunchForce = 160;

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
		if(Owner.ActorLocation.Z < Boss.ArenaFloorZ)
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

		TargetLocation = Boss.CurrentTargetPlayer.ActorLocation;
		TargetLocation.Z = Boss.ArenaFloorZ;

		JumpTrajectory.LaunchLocation = Owner.ActorLocation;
		JumpTrajectory.LandLocation = TargetLocation;
		JumpTrajectory.Gravity = FVector::DownVector * JumpComp.FallSpeed;
		JumpTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Owner.ActorLocation, TargetLocation, JumpComp.FallSpeed, JumpComp.JumpHeight);

		JumpComp.JumpsInRow++;

		Boss.Mesh.SetAnimTrigger(n"Jump");

		// if(TargetLocation.Y < Owner.ActorLocation.Y)
		// 	Boss.RotateTowards(FQuat::MakeFromEuler(FVector::UpVector * JumpComp.JumpingYaw));
		// else if(TargetLocation.Y > Owner.ActorLocation.Y)
		// 	Boss.RotateTowards(FQuat::MakeFromEuler(FVector::UpVector * -JumpComp.JumpingYaw));
		// else
		Boss.RotateTowards(FQuat(0,0,0,1));

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

		Boss.Mesh.SetAnimTrigger(n"Land");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//JumpTrajectory.DrawDebug(FLinearColor::Blue, 0);

		float Duration = ActiveDuration * JumpComp.JumpSpeed;

		const FVector StartLocation = JumpTrajectory.GetLocation(Duration);
		
		const FVector EndLocation = JumpTrajectory.GetLocation(Duration);

        FHitResult Hit = Sweep(StartLocation, EndLocation);

        if(Hit.bBlockingHit)
        {
            Owner.SetActorLocation(Hit.Location);
        }
        else
        {
			const FVector Velocity = JumpTrajectory.GetVelocity(Duration);
			//const FQuat NewRotation = FQuat::MakeFromXZ(Velocity, Owner.ActorUpVector);
           	Owner.SetActorLocation(EndLocation);
			Owner.SetActorVelocity(Velocity);
        }
	}

	FHitResult Sweep(FVector StartLocation, FVector EndLocation)
    {
        FHazeTraceSettings Settings = GetTraceSettings();

        const FHitResult Hit = Settings.QueryTraceSingle(
			StartLocation,
			EndLocation
		);

        return Hit;
    }

	FHazeTraceSettings GetTraceSettings() const
    {
		FHazeTraceSettings Settings = Trace::InitChannel(ETraceTypeQuery::Visibility, n"SketchbookBoss");
        Settings.UseLine();
		Settings.IgnorePlayers();
		Settings.SetTraceComplex(false);
        return Settings;
    }
};