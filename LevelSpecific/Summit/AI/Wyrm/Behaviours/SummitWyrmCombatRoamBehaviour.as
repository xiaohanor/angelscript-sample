// Roam randomly, but don't stray to far from target
class USummitWyrmCombatRoamBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitWyrmSettings WyrmSettings;
	FVector RoamDestination;
	FHazeAcceleratedVector AccDestination;
	float DestinationTime;
	int NumFailedDestinations;

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
		NumFailedDestinations = 0;
		DestinationTime = Time::GameTimeSeconds;
		FindDestination(WyrmSettings.RoamAngle, RoamDestination);
		AccDestination.SnapTo(Owner.ActorForwardVector * (RoamDestination - Owner.ActorLocation).Size());
	}

	bool FindDestination(float Angle, FVector& Destination)
	{
		FVector Center = (Owner.ActorVelocity.IsNearlyZero(10.0) ? Owner.ActorForwardVector : Owner.ActorVelocity);

		// Turn towards target when far away
		FVector ToTarget = (TargetComp.Target.ActorLocation - Owner.ActorLocation);
		if (ToTarget.SizeSquared2D() > Math::Square(WyrmSettings.RoamMaxRange))
			Center = Center.RotateTowards((Owner.ActorRightVector.DotProduct(ToTarget) > 0.0) ? Owner.ActorRightVector : -Owner.ActorRightVector, Angle);			

		FVector Dir = Math::GetRandomConeDirection(Center, Math::DegreesToRadians(Angle));
		float HeightDiff = Owner.ActorLocation.Z - TargetComp.Target.ActorLocation.Z;
		if (((HeightDiff > WyrmSettings.RoamHeightMax) && (Dir.Z > 0.0)) ||
			((HeightDiff < WyrmSettings.RoamHeightMin) && (Dir.Z < 0.0)))
			Dir.Z = 0.0;

		Destination = Owner.ActorLocation + Dir * WyrmSettings.RoamSpeed * 2.0; 
		if (Navigation::NavOctreeLineTrace(Owner.ActorLocation, Destination, 200))
		{
			// No path, continue forward while attempting to find another way
			Destination = Owner.ActorLocation + Center * WyrmSettings.RoamSpeed * 2.0;
			return false;
		}
		// Destination can be reached!
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((Time::GameTimeSeconds > DestinationTime + 2.0) || Owner.ActorLocation.IsWithinDist(RoamDestination, BasicSettings.RoamRadius * 0.5))
		{
			float RoamAngle = Math::Min(WyrmSettings.RoamAngle + NumFailedDestinations * 10.f, 150.0);
			if (FindDestination(RoamAngle, RoamDestination))
			{
				DestinationTime = Time::GameTimeSeconds;
				NumFailedDestinations = 0;
			}
			else
			{
				NumFailedDestinations++;
			}
		}

		// Move to slowly changing destination with an offset to get snakey undulations
		AccDestination.AccelerateTo(RoamDestination, 10.0, DeltaTime);
		FVector Direction = (AccDestination.Value - Owner.ActorLocation).GetSafeNormal();
		float UndulationTime = ActiveDuration * WyrmSettings.UndulationFrequency;
		FVector UndulationDir = Owner.ActorRightVector * Math::Sin(UndulationTime) * WyrmSettings.UndulationAmount;
		UndulationDir += Owner.ActorUpVector * Math::Sin(UndulationTime * 0.2) * Math::Sin(UndulationTime) * WyrmSettings.UndulationAmount * 0.5;
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + (Direction + UndulationDir) * WyrmSettings.RoamSpeed, WyrmSettings.RoamSpeed);

		// Look at destination
		DestinationComp.RotateTowards(AccDestination.Value);
	}
}