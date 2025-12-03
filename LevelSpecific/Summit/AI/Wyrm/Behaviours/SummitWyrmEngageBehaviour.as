// Move into position to attack target
class USummitWyrmEngageBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitWyrmSettings WyrmSettings;
	FVector EngageDestination;
	FHazeAcceleratedVector AccDestination;
	float DestinationTime;

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
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, WyrmSettings.EngageMaxRange))
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
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, WyrmSettings.EngageMaxRange * 1.2))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DestinationTime = Time::GameTimeSeconds;
		FindDestination(EngageDestination);
		AccDestination.SnapTo(Owner.ActorForwardVector * (EngageDestination - Owner.ActorLocation).Size());
	}

	bool FindDestination(FVector& Destination)
	{		
		FVector RightDirection = TargetComp.Target.ActorRightVector;

		// If already facing the target or far enough away we turning towards target
		FVector FromTarget = (Owner.ActorLocation - TargetComp.Target.ActorLocation);
		float TurnDirectionSign = 1.0;

		if ((RightDirection.DotProduct(FromTarget) < 0.0))	
			TurnDirectionSign = -1.0;
				
		Destination = TargetComp.Target.ActorLocation + RightDirection * TurnDirectionSign * WyrmSettings.EngageTurnRange;
		FVector ToDestinationDir = (Destination - Owner.ActorLocation).GetSafeNormal();
		float LookAheadRange = 1000;
		if (Navigation::NavOctreeLineTrace(Owner.ActorLocation, Owner.ActorLocation + ToDestinationDir * LookAheadRange, 200))
		{
			// No path, continue forward 
			Destination = Owner.ActorLocation + Owner.ActorForwardVector * WyrmSettings.EngageSpeed * 2.0;
			return false;
		}
		// Destination can be reached!
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((Time::GameTimeSeconds > DestinationTime + 1.0) || Owner.ActorLocation.IsWithinDist(EngageDestination, WyrmSettings.EngageSpeed * 0.5))
		{
			if (FindDestination(EngageDestination))
				DestinationTime = Time::GameTimeSeconds; // New destination
			else
				Cooldown.Set(4); // Let other behaviour get us out of this pickle
		}

		// Move to slowly changing destination with an offset to get snakey undulations
		AccDestination.AccelerateTo(EngageDestination, 5.0, DeltaTime);
		FVector Direction = (AccDestination.Value - Owner.ActorLocation).GetSafeNormal();
		float UndulationTime = ActiveDuration * WyrmSettings.UndulationFrequency;
		FVector UndulationDir = Owner.ActorRightVector * Math::Sin(UndulationTime) * WyrmSettings.UndulationAmount;
		UndulationDir += Owner.ActorUpVector * Math::Sin(UndulationTime * 0.2) * Math::Sin(UndulationTime) * WyrmSettings.UndulationAmount * 0.5;
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + (Direction + UndulationDir) * WyrmSettings.EngageSpeed, WyrmSettings.EngageSpeed);

		// Look at destination
		DestinationComp.RotateTowards(AccDestination.Value);
	}
}