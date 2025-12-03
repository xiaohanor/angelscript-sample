
class UIslandShieldotronKeepDistanceBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		float EvadeRange = 1500;
		FVector ToTarget = TargetComp.Target.ActorLocation - Owner.ActorLocation;
		ToTarget.Normalize();
		//Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToTarget * EvadeRange, FLinearColor::Green, Duration = 1.0);
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, EvadeRange)) //BasicSettings.EvadeRange
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

	FVector AwayOffset;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
				
		AwayOffset = Owner.ActorRightVector * Math::RandRange(-100,100);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(4.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move away from target until at proper distance or duration is up
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector AwayFromTarget = (OwnLoc - TargetLoc);
		AwayFromTarget.Z = Math::Max(0.0, AwayFromTarget.Z); // Don't try to dig a hole!
		FVector AwayLoc = OwnLoc + AwayFromTarget.GetSafeNormal() * (DestinationComp.MinMoveDistance + 80.0);
		AwayLoc += AwayOffset;

		DestinationComp.MoveTowards(AwayLoc, BasicSettings.EvadeMoveSpeed);
		DestinationComp.RotateTowards(TargetComp.Target);
		
		if (ActiveDuration > 1.0) // BasicSettings.EvadeMinDuration
		{
			if (!Owner.ActorLocation.IsWithinDist(TargetLoc, 3000)) // BasicSettings.EvadeRange - better with a gap between min and max range
			{
				Cooldown.Set(0.5);
				return;
			}

			if (ActiveDuration > BasicSettings.EvadeMaxDuration)
			{
				Cooldown.Set(4.0);
				return;
			}
		}
	}
}