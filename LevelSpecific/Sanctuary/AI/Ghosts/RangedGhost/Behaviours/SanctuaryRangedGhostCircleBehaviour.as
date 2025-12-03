class USanctuaryRangedGhostCircleBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	bool bTriedBothDirections = false;

	UFitnessUserComponent FitnessComp;
	UFitnessStrafingComponent FitnessStrafingComp;
	USanctuaryRangedGhostSettings GhostSettings;
	AHazeCharacter Ghost;

	private float FlipCooldownTime;
	private float FlipCooldownDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Ghost = Cast<AHazeCharacter>(Owner);
		FitnessComp = UFitnessUserComponent::GetOrCreate(Owner);
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
		GhostSettings = USanctuaryRangedGhostSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, GhostSettings.CircleEnterRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, GhostSettings.CircleMaxRange))
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bTriedBothDirections = false;
		FlipCooldownTime = 0;
		FitnessStrafingComp.SetClosestToViewStrafeDirection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc);
		Side = Side.GetClampedToSize(DestinationComp.MinMoveDistance + 80.0, DestinationComp.MinMoveDistance + 200.0);
		if (FitnessStrafingComp.bStrafeLeft)
			Side *= -1.0;
		FVector CircleDir = (OwnLoc + Side - TargetLoc).GetSafeNormal();
		FVector StrafeDest = TargetLoc + CircleDir * GhostSettings.CircleDistance;
		StrafeDest.Z = TargetLoc.Z + GhostSettings.CircleHeight + GhostSettings.CircleWobble * Math::Sin(ActiveDuration * 2.0);
		DestinationComp.MoveTowardsIgnorePathfinding(StrafeDest, GhostSettings.CircleSpeed);
		
		if(!CanMove(StrafeDest, OwnLoc))
		{
			FitnessStrafingComp.FlipStrafeDirection();
			Cooldown.Set(1.0);
			return;
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player != nullptr && !FitnessComp.ShouldMoveToLocation(Player, StrafeDest) && (FlipCooldownTime == 0 || Time::GetGameTimeSince(FlipCooldownTime) > FlipCooldownDuration))
		{
			FitnessStrafingComp.FlipStrafeDirection();
			FlipCooldownTime = Time::GetGameTimeSeconds();
		}
		
		if (DestinationComp.MoveFailed())
		{
			if (bTriedBothDirections)
				Cooldown.Set(2.0); // Stuck, try again in a while
			FitnessStrafingComp.FlipStrafeDirection();
			bTriedBothDirections = true;
		}
	}

	bool CanMove(FVector StrafeDest, FVector OwnLoc)
	{
		FVector OffsetOwnLoc = OwnLoc + ((StrafeDest - OwnLoc).GetSafeNormal() * Ghost.CapsuleComponent.CapsuleRadius);
		FVector OwnLocTree;
		if(!Navigation::NavOctreeGetNearestLocationInTree(OffsetOwnLoc, 500, Ghost.CapsuleComponent.CapsuleRadius, OwnLocTree))
			return false;
		if(Navigation::NavOctreeLineTrace(OwnLocTree, StrafeDest))
			return false;
		
		if(!PerceptionComp.Sight.VisibilityExists(Owner, TargetComp.Target, (StrafeDest-OwnLoc)))
			return false;
		return true;
	}
}