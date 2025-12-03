
// Move towards enemy
class UPrisonGuardChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeTeam Team;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Team = UPrisonGuardComponent::Get(Owner).JoinTeam();
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
	void TickActive(float DeltaTime)
	{
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.ChaseMinRange))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		if ((ActiveDuration > 0.5) && IsObstructedByTeamMate())
		{
			// Stop to form an orderly line when friends are in the way
			Cooldown.Set(Math::RandRange(0.4, 0.7));
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, BasicSettings.ChaseMoveSpeed);
	}

	bool IsObstructedByTeamMate()
	{
		if (Owner.ActorVelocity.IsNearlyZero(100.0))
			return false;

		FVector MoveDir = Owner.ActorVelocity.GetSafeNormal2D();
		FVector WantedLoc = Owner.ActorLocation + MoveDir * 40.0;
		for (AHazeActor Coworker : Team.GetMembers())
		{
			if (Coworker == Owner)
				continue;
			if (!Coworker.ActorLocation.IsWithinDist(WantedLoc, 120.0))
				continue;
			if (MoveDir.DotProduct(Coworker.ActorLocation - Owner.ActorLocation) < 0.0)
				continue;
			return true;
		}
		return false;
	}
}