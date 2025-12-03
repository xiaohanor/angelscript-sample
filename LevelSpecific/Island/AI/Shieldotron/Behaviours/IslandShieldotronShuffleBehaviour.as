
class UIslandShieldotronShuffleBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UPathfollowingSettings PathingSettings;

	UIslandShieldotronSettings Settings;

	bool bMoveForward = false;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		// if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Math::Min(Settings.CircleStrafeEnterRange, Settings.CircleStrafeMaxRange*2)))
		// 	return false;
		// if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.CircleStrafeMinRange))
		// 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		// if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.CircleStrafeMaxRange*2))
		// 	return true;
		// if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.CircleStrafeMinRange))
		// 	return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bMoveForward = !bMoveForward;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Move = (TargetLoc - OwnLoc).GetSafeNormal2D();
		Move = Move.GetClampedToSize(DestinationComp.MinMoveDistance, DestinationComp.MinMoveDistance + 80.0);
		if (!bMoveForward)
			Move *= -1.0;
				
		FVector Dest = Owner.ActorLocation + Move;
		if (CanMove(Dest))
			DestinationComp.MoveTowards(Dest, Settings.SidestepStrafeSpeed);

		DestinationComp.RotateTowards(TargetComp.Target);
		
		if (DoChangeDirection(Dest))
			Cooldown.Set(4.0);

		if (ActiveDuration > 2.0)
			Cooldown.Set(6.0);
	}
	
	private bool DoChangeDirection(FVector Dest)
	{
		if(DestinationComp.MoveFailed())
			return true;

		if (PathingSettings.bIgnorePathfinding)
			return false;
		
		FVector StrafeDestNavMesh;
		FVector PathStrafeDest = Dest + (Dest - Owner.ActorLocation).GetSafeNormal() * Radius * 4.0;
		if(!Pathfinding::FindNavmeshLocation(PathStrafeDest, 0.0, 100.0, StrafeDestNavMesh))
			return true;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, StrafeDestNavMesh))
			return true;

		return false;
	}

	private bool CanMove(FVector Dest)
	{
		FVector StrafeDestNavMesh;
		FVector PathStrafeDest = Dest + (Dest - Owner.ActorLocation).GetSafeNormal() * Radius * 4.0;
		//Debug::DrawDebugSphere(PathStrafeDest, Duration = 1.0);
		if(!Pathfinding::FindNavmeshLocation(PathStrafeDest, 0.0, 100.0, StrafeDestNavMesh))
			return false;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, StrafeDestNavMesh))
			return false;

		return true;
	}
}