class USketchbookBossUndergroundJumpCapability : USketchbookCrabBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction); 

	FVector OriginalLocation;
	FVector TargetLocation;

	USketchbookBossJumpComponent JumpComp;

	FTraversalTrajectory JumpTrajectory;
	const float Gravity = 50;
	const float Speed = 7;

	const float AnticipationTime = 1;
	bool bHasJumped = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JumpComp = USketchbookBossJumpComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (CrabComp.SubPhase != ESketchbookCrabBossSubPhase::Jump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < AnticipationTime)
			return false;

		if (Owner.ActorLocation.Z <= Boss.ArenaFloorZ && Owner.ActorVelocity.DotProduct(FVector::DownVector) > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.Mesh.SetAnimTrigger(n"AnticipateJump");

		CrabComp.bIsUnderground = false;
		Owner.SetActorVelocity(FVector::ZeroVector);
		OriginalLocation = Owner.ActorLocation;

		JumpTrajectory.LaunchLocation = Owner.ActorLocation;
		JumpTrajectory.LandLocation = Owner.ActorLocation;
		JumpTrajectory.LandLocation.Z = Boss.ArenaFloorZ;
		JumpTrajectory.Gravity = FVector::DownVector * Gravity;
		JumpTrajectory.LaunchVelocity = FVector::UpVector * CrabComp.JumpVelocity;

		Boss.RotateTowards(FQuat::MakeFromEuler(FVector::UpVector * 0));
		JumpComp.JumpsInRow++;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FVector NewLocation = Owner.ActorLocation;
		NewLocation.Z = Boss.ArenaFloorZ;
		Owner.SetActorLocation(NewLocation);

		if (CrabComp.bMainSequenceActive)
		{
			CrabComp.SubPhase = ESketchbookCrabBossSubPhase::Shoot;
		}
		else
			CrabComp.SubPhase = ESketchbookCrabBossSubPhase::Bury;

		USketchbookBossEffectEventHandler::Trigger_OnLand(Boss);
		bHasJumped = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < AnticipationTime)
			return;

		if(!bHasJumped)
		{
			Boss.Mesh.SetAnimTrigger(n"Jump");
			USketchbookBossEffectEventHandler::Trigger_OnAttack(Boss);
		}

		JumpTrajectory.DrawDebug(FLinearColor::Blue, 0);
		float Duration = (ActiveDuration - AnticipationTime) * Speed;
		
		const FVector NewLocation = JumpTrajectory.GetLocation(Duration);
        
		const FVector Velocity = JumpTrajectory.GetVelocity(Duration);

		Owner.SetActorLocation(NewLocation);
		Owner.SetActorVelocity(Velocity);

		bHasJumped = true;
	}
};