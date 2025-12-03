
class USummitWyrmChargeBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitWyrmSettings WyrmSettings;
	FVector Origin;
	FVector TargetDestination;
	FHazeAcceleratedVector AccDestination;
	AHazeActor Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WyrmSettings = USummitWyrmSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;
		FVector OwnLoc = Owner.ActorCenterLocation;
		if (!OwnLoc.IsWithinDist(TargetLoc, WyrmSettings.ChargeMaxRange))
			return false; // Too far
		if (OwnLoc.IsWithinDist(TargetLoc, WyrmSettings.ChargeMinRange))
			return false; // Too close
		FVector CurDir = Owner.ActorForwardVector;
		if (!Owner.ActorVelocity.IsNearlyZero(10.0)) 
			CurDir = Owner.ActorVelocity.GetSafeNormal();
		if (CurDir.DotProduct((TargetLoc - OwnLoc).GetSafeNormal()) < Math::Cos(Math::DegreesToRadians(WyrmSettings.ChargeMaxAngle)))
			return false; // Need to turn too much
		if (Navigation::NavOctreeLineTrace(OwnLoc, TargetLoc + FVector(0.0, 0.0, 200.0), 200.0))
			return false; // Blocked path to just above target.
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		Origin = Owner.ActorLocation;
		TargetDestination = GetDestination();
		AccDestination.SnapTo(Owner.ActorForwardVector * (TargetDestination - Owner.ActorLocation).Size());
	}

	FVector GetDestination()
	{
		return Owner.ActorLocation + (Target.ActorLocation - Owner.ActorLocation) * 1.5;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = Target.ActorLocation;

		if (ActiveDuration < WyrmSettings.ChargeTrackDuration)
			TargetDestination = GetDestination();

		// Undulating charge!
		float Speed = (ActiveDuration < WyrmSettings.ChargeTelegraphDuration) ? WyrmSettings.ChargeTelegraphSpeed : WyrmSettings.ChargeSpeed;
		AccDestination.AccelerateTo(TargetDestination, 2.0, DeltaTime);
		FVector Direction = (AccDestination.Value - Owner.ActorLocation).GetSafeNormal();
		float UndulationTime = ActiveDuration * WyrmSettings.UndulationFrequency * Math::Min(ActiveDuration, 1.0) * 3.0; // More violent undulation
		float UndulationAmount = WyrmSettings.UndulationAmount;
		if (OwnLoc.IsWithinDist(TargetLoc, WyrmSettings.ChargeMinRange))
			UndulationAmount = 0.0;
		FVector UndulationDir = Owner.ActorRightVector * Math::Sin(UndulationTime) * UndulationAmount;
		UndulationDir += Owner.ActorUpVector * Math::Sin(UndulationTime * 0.2) * Math::Sin(UndulationTime) * UndulationAmount * 0.5;
		FVector TelegraphRiseDir = Owner.ActorUpVector * WyrmSettings.ChargeTelegraphRise * Math::Max(WyrmSettings.ChargeTelegraphDuration - ActiveDuration, 0.0);
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + (Direction + UndulationDir + TelegraphRiseDir) * Speed, Speed);

		// Look at destination
		DestinationComp.RotateTowards(AccDestination.Value);

		if (HasCompletedCharge())
			Cooldown.Set(WyrmSettings.ChargeCooldown);
	}

	bool HasCompletedCharge()
	{
		if (ActiveDuration > WyrmSettings.ChargeMaxDuration)
			return true;

		if ((TargetDestination - Origin).DotProduct(TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation) < 0.0)
			return true;

		return false;
	}
}