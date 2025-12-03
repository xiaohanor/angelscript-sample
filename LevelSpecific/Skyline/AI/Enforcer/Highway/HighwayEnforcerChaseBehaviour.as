
// Move towards enemy
class UHighwayEnforcerChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USkylineEnforcerBoundsComponent BoundsComp;

	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BoundsComp = USkylineEnforcerBoundsComponent::GetOrCreate(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
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
		FVector TargetLocation = TargetComp.Target.ActorLocation;

		if (Owner.ActorLocation.IsWithinDist(TargetLocation, BasicSettings.ChaseMinRange))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		FVector Dir = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
		FVector ChaseLoc = Owner.ActorLocation + Dir * (DestinationComp.MinMoveDistance + 80.0);

		if(!BoundsComp.LocationIsWithinBounds(ChaseLoc + (Owner.ActorUpVector * Radius), Radius))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowardsIgnorePathfinding(TargetLocation, BasicSettings.ChaseMoveSpeed);
	}
}