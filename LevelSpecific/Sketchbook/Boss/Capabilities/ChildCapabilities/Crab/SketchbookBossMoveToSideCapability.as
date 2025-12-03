class USketchbookBossMoveToSideCapability : USketchbookCrabBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	FVector TargetLocation;

	bool bTargetingLeftSide;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CrabComp.SubPhase != ESketchbookCrabBossSubPhase::MoveToEdge)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Owner.ActorLocation.Distance(TargetLocation) <= SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Move to whichever side is (not) closest
		float RightSide = Boss.GetArenaRightSide() - 250;
		float LeftSide = Boss.GetArenaLeftSide() + 250;

		bTargetingLeftSide = (Math::Abs(Owner.ActorLocation.Y - LeftSide) < Math::Abs(Owner.ActorLocation.Y - RightSide));

		if(bTargetingLeftSide)
			TargetLocation = FVector(0, LeftSide, Boss.ArenaFloorZ - CrabComp.BuryDepth);
		else
			TargetLocation = FVector(0, RightSide, Boss.ArenaFloorZ - CrabComp.BuryDepth);

		// const float TargetYaw = bTargetingLeftSide ? -CrabComp.ProjectileFiringYaw : CrabComp.ProjectileFiringYaw;
		// FQuat TargetRotation = FQuat::MakeFromEuler(FVector::UpVector * TargetYaw);
		// Boss.RotateTowards(TargetRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CrabComp.SubPhase = ESketchbookCrabBossSubPhase::Jump;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector NewLocation = Math::VInterpConstantTo(Owner.ActorLocation, TargetLocation, DeltaTime, CrabComp.HorizontalMoveSpeed);
		Owner.SetActorLocation(NewLocation);
	}
};