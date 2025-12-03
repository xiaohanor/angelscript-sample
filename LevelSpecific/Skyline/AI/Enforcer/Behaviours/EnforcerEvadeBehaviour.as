
class UEnforcerEvadeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UFitnessStrafingComponent FitnessStrafingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FitnessStrafingComp = UFitnessStrafingComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.EvadeRange))
			return false;
		if (!TargetComp.HasVisibleTarget())
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
		// Use defensive stance, unless using weapon
		if (BehaviourComp.CanClaimRequirement(EBasicBehaviourRequirement::Weapon, 0, this))
			AnimComp.RequestOverrideFeature(LocomotionFeatureAISkylineTags::EnforcerStances, this);
		else
			AnimComp.RequestOverrideFeature(NAME_None, this);

		// Move away from target until at proper distance or duration is up
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector AwayFromTarget = (OwnLoc - TargetLoc);
		AwayFromTarget.Z = Math::Max(0.0, AwayFromTarget.Z); // Don't try to dig a hole!
		FVector AwayLoc = OwnLoc + AwayFromTarget.GetSafeNormal() * (DestinationComp.MinMoveDistance + 80.0);
		DestinationComp.MoveTowards(AwayLoc, BasicSettings.EvadeMoveSpeed);
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