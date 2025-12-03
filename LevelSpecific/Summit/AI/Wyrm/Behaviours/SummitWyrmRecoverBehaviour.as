// Continue moving forawrd a while after charge
class USummitWyrmRecoverBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitWyrmSettings WyrmSettings;
	FVector RecoverDirection;
	FHazeAcceleratedVector AccDestination;
	USummitWyrmPivotComponent PivotComp;
	FHazeAcceleratedFloat AccSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WyrmSettings = USummitWyrmSettings::GetSettings(Owner);
		PivotComp = USummitWyrmPivotComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		FVector CurFwd = PivotComp.WorldRotation.Vector();
		RecoverDirection = CurFwd.GetSafeNormal();
		AccDestination.SnapTo(CurFwd * 10000.0);
		AccSpeed.SnapTo(WyrmSettings.RecoverSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		TargetComp.SetTarget(nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move to changing destination with an offset to get snakey undulations
		float Speed = AccSpeed.AccelerateTo(WyrmSettings.RecoverSpeed, WyrmSettings.RecoverDuration - ActiveDuration + 1.0, DeltaTime);
		AccDestination.AccelerateTo(Owner.ActorLocation + RecoverDirection * 10000, 2.0, DeltaTime);
		FVector Direction = (AccDestination.Value - Owner.ActorLocation).GetSafeNormal();
		float UndulationTime = ActiveDuration * WyrmSettings.UndulationFrequency * 2.0;
		FVector UndulationDir = Owner.ActorRightVector * Math::Sin(UndulationTime) * WyrmSettings.UndulationAmount * 2.0;
		UndulationDir += Owner.ActorUpVector * Math::Sin(UndulationTime * 0.2) * Math::Sin(UndulationTime) * WyrmSettings.UndulationAmount * 1.0;
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + (Direction + UndulationDir) * Speed, Speed);

		// Look at destination
		DestinationComp.RotateTowards(AccDestination.Value);

		// Check if we should bail out due to time or obstructions
		if (ActiveDuration > WyrmSettings.RecoverDuration)
			DeactivateBehaviour();
		else if ((ActiveDuration > 0.5) && Navigation::NavOctreeLineTrace(Owner.ActorLocation, Owner.ActorLocation + RecoverDirection * Speed * 0.5, 200))
			DeactivateBehaviour();
	}
}