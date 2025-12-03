class USketchbookBossJumpToEdgeCapability : USketchbookDemonBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	FVector TargetLocation;

	USketchbookBossJumpComponent LandingComp;

	FTraversalTrajectory JumpTrajectory;

	float LaunchForce = 160;

	float Gravity = 25;

	float Speed = 10;

	bool bTargetingLeftSide;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		LandingComp = USketchbookBossJumpComponent::Get(Owner);
		LandingComp.LandingLocation = Owner.ActorLocation;
		LandingComp.LandingLocation.Z = Boss.ArenaFloorZ;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DemonComp.SubPhase != ESketchbookDemonBossSubPhase::JumpToEdge)
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
		//Jump to whichever side is (not) closest
		float RightSide = Boss.GetArenaRightSide() - 200;
		float LeftSide = Boss.GetArenaLeftSide() + 200	;

		bTargetingLeftSide = (Math::Abs(Owner.ActorLocation.Y - LeftSide) < Math::Abs(Owner.ActorLocation.Y - RightSide));

		if(bTargetingLeftSide)
			TargetLocation = FVector(0, LeftSide, Boss.ArenaFloorZ);
		else
			TargetLocation = FVector(0, RightSide, Boss.ArenaFloorZ);

		JumpTrajectory.LaunchLocation = Owner.ActorLocation;
		JumpTrajectory.LandLocation = TargetLocation;
		JumpTrajectory.Gravity = FVector::DownVector * Gravity;
		JumpTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Owner.ActorLocation, TargetLocation, Gravity, 600);

		LandingComp.JumpsInRow++;

		USketchbookBossEffectEventHandler::Trigger_OnJump(Boss);

		Boss.Mesh.SetAnimTrigger(n"Jump");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DemonComp.SubPhase = ESketchbookDemonBossSubPhase::FlyToCorner;

		Boss.Idle(1);
		
		FVector FixedLocation = Owner.ActorLocation;
		FixedLocation.Z = Boss.ArenaFloorZ;
		Owner.SetActorLocation(FixedLocation);

		// const float TargetYaw = bTargetingLeftSide ? DemonComp.ProjectileFiringYaw : -DemonComp.ProjectileFiringYaw;
		// FQuat TargetRotation = FQuat::MakeFromEuler(FVector::UpVector * TargetYaw);
		// Boss.RotateTowards(TargetRotation);
		Boss.RotateTowards(FQuat(0,0,0,1));

		USketchbookBossEffectEventHandler::Trigger_OnLand(Boss);

		Boss.Mesh.SetAnimTrigger(n"Land");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Duration = ActiveDuration * Speed;

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