class USketchbookBossCrushTextCapability : USketchbookBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	FVector TargetLocation;

	FTraversalTrajectory JumpTrajectory;

	float LaunchForce = 270;
	float FallSpeed = 50;
	float JumpHeight = 200;
	float JumpSpeed = 5;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.bCrushedText)
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
		Boss.Mesh.SetAnimTrigger(n"Jump");
	 	TargetLocation = Boss.BossText.ActorLocation;
		TargetLocation.Z = Boss.ArenaFloorZ;

		JumpTrajectory.LaunchLocation = Owner.ActorLocation;
		JumpTrajectory.LandLocation = TargetLocation;
		JumpTrajectory.Gravity = FVector::DownVector * FallSpeed;
		JumpTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Owner.ActorLocation, TargetLocation, FallSpeed, JumpHeight);

		USketchbookBossEffectEventHandler::Trigger_OnJump(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.Mesh.SetAnimTrigger(n"Land");

		Owner.SetActorLocation(TargetLocation);

		if(Boss.BossNumber == 1)
			Boss.StartMainAttackSequence();

		USketchbookBossEffectEventHandler::Trigger_OnLand(Boss);
		Boss.Idle(Boss.JumpComp.WaitAfterJumpDuration);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Boss.bCrushedText)
		{
			if(Boss.ActorLocation.Z < Boss.BossText.ActorLocation.Z)
			{
				Boss.bCrushedText = true;
				Boss.BossText.DrawableSentenceComp.ImmediatelyErase();
			}
		}

		float Duration = ActiveDuration * JumpSpeed;

		const FVector StartLocation = JumpTrajectory.GetLocation(Duration);
		
		const FVector EndLocation = JumpTrajectory.GetLocation(Duration);

		const FVector Velocity = JumpTrajectory.GetVelocity(Duration);
		Owner.SetActorLocation(EndLocation);
		Owner.SetActorVelocity(Velocity);
	}
};