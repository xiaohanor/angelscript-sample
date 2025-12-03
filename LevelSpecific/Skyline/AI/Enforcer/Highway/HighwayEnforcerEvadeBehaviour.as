
class UHighwayEnforcerEvadeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UFitnessStrafingComponent FitnessStrafingComp;
	USkylineEnforcerBoundsComponent BoundsComp;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
		BoundsComp = USkylineEnforcerBoundsComponent::GetOrCreate(Owner);

		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.EvadeRange))
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
	void OnDeactivated()
	{
		Super::OnDeactivated();
		FitnessStrafingComp.OptimizeStrafeDirection();
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Always be strafing
		AnimComp.RequestOverrideFeature(LocomotionFeatureAISkylineTags::EnforcerStances, this);
		
		// Move away from target until at proper distance or duration is up
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector AwayFromTarget = (OwnLoc - TargetLoc);
		AwayFromTarget.Z = Math::Max(0.0, AwayFromTarget.Z); // Don't try to dig a hole!
		FVector AwayLoc = OwnLoc + AwayFromTarget.GetSafeNormal() * (DestinationComp.MinMoveDistance + 80.0);

		if(!BoundsComp.LocationIsWithinBounds(AwayLoc + (Owner.ActorUpVector * Radius), Radius))
		{
			Cooldown.Set(0.5);
			return;
		}

		DestinationComp.MoveTowardsIgnorePathfinding(AwayLoc, BasicSettings.EvadeMoveSpeed);
		DestinationComp.RotateTowards(TargetComp.Target);

		if (ActiveDuration > BasicSettings.EvadeMinDuration)
		{
			if (!OwnLoc.IsWithinDist(TargetLoc, BasicSettings.EvadeRange))
			{
				Cooldown.Set(0.5);
				return;
			}

			if (ActiveDuration > BasicSettings.EvadeMaxDuration)
			{
				Cooldown.Set(2.0);
				return;
			}
		}
	}
}