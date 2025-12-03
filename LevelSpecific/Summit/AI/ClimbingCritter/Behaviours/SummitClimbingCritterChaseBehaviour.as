
// Move towards enemy
class USummitClimbingCritterChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UWallclimbingComponent WallClimbingComp;
	USummitClimbingCritterSettings CritterSettings;

	// Crude obstacle avoidance until pathfiding works properly
	float FreeDuration = 0.0;
	float ObstacleAvoidanceFactor = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CritterSettings = USummitClimbingCritterSettings::GetSettings(Owner);
		WallClimbingComp = UWallclimbingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.ChaseMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		FreeDuration = 0.0;
		ObstacleAvoidanceFactor = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.ChaseMinRange))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		// TODO: Pathfinding sucks for the walls critters climb on, just check if there is navmesh and use crude obstacle avoidance
		// where we want to go and in front of us instead for now
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector ToTarget = (TargetLoc - Owner.ActorLocation); 
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, CritterSettings.ChaseMoveDistance))
		{
			TargetLoc = Owner.ActorLocation + (TargetComp.Target.ActorLocation - Owner.ActorLocation).VectorPlaneProject(Owner.ActorUpVector).GetSafeNormal() * CritterSettings.ChaseMoveDistance;
			if (ToTarget.DotProduct(Owner.ActorUpVector) > 0.0)
				TargetLoc += ToTarget.GetSafeNormal() * CritterSettings.ChaseMoveDistance * 0.1; // Bias towards target so we won't get stuck on perpendicular ceiling
		}

		DestinationComp.MoveTowardsIgnorePathfinding(TargetLoc, BasicSettings.ChaseMoveSpeed);

		// if (Math::Abs(ObstacleAvoidanceFactor) > 0.0)
		// {
		// 	// Add offset for obstacle avoidance (never more than 90 degrees)
		// 	FVector AvoidDir = ToTarget + ToTarget.CrossProduct(Owner.ActorUpVector) * ObstacleAvoidanceFactor;
		// 	if (Math::Abs(ObstacleAvoidanceFactor) > 10.0)
		// 		AvoidDir -= ToTarget * (Math::Abs(ObstacleAvoidanceFactor) - 10.0);
		// 	TargetLoc = Owner.ActorLocation + AvoidDir.GetSafeNormal() * CritterSettings.ChaseMoveDistance;	
		// }

		// // Make sure we don't check other side of wall
		// FVector PathLoc = TargetLoc + Owner.ActorUpVector * 50.0;
		// if ((WallClimbingComp.Navigation == nullptr) || WallClimbingComp.Navigation.FindLocationOnNavmesh(PathLoc, PathLoc, 0.0, 400, 40, Owner.ActorUpVector))
		// {
		// 	// Move!
		// 	DestinationComp.MoveTowardsIgnorePathfinding(TargetLoc, BasicSettings.ChaseMoveSpeed);

		// 	// Return to target direction after a while
		// 	FreeDuration += DeltaTime;
		// 	if (FreeDuration > 0.5)
		// 		ObstacleAvoidanceFactor *= 1.0 - DeltaTime * 3.0;
		// 	if (Math::Abs(ObstacleAvoidanceFactor) < 0.5)
		// 		ObstacleAvoidanceFactor = 0.0;
		// }
		// else
		// {
		// 	// Slow to a stop, while trying obstacle avoidance
		// 	FreeDuration = 0.0;
		// 	if (Math::Abs(ObstacleAvoidanceFactor) < 0.5)
		// 	{
		// 		// Keep to velocity or go in random direction if stationary
		// 		if (Owner.ActorVelocity.IsNearlyZero(10.0))
		// 			ObstacleAvoidanceFactor = Math::RandBool() ? 0.5 : -0.5; 
		// 		else if (Owner.ActorVelocity.DotProduct(ToTarget.CrossProduct(Owner.ActorUpVector)) > 0.0)
		// 			ObstacleAvoidanceFactor = 0.5;
		// 		else
		// 			ObstacleAvoidanceFactor = -0.5;
		// 	}
		// 	else if (Math::Abs(ObstacleAvoidanceFactor) > 100.0)
		// 	{
		// 		// This direetion is no good, switch to other				
		// 		ObstacleAvoidanceFactor = -Math::Sign(ObstacleAvoidanceFactor) * 0.5;
		// 	}
		// 	else
		// 	{
		// 		// Still not free, widen angle
		// 		ObstacleAvoidanceFactor *= 1.0 + DeltaTime * 10.0; 
		// 	}
		// }
	}
}