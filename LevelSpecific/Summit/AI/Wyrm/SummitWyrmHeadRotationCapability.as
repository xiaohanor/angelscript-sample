class USummitWyrmHeadRotationCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(n"SummitWyrm");
	default CapabilityTags.Add(n"SummitWyrmHeadRotation");

	UBasicAIDestinationComponent DestinationComp;
	USummitWyrmPivotComponent Pivot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		Pivot = USummitWyrmPivotComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// TODO: Need networking
		if (DestinationComp.FollowSpline != nullptr)
		{
	 		Pivot.SetWorldRotation(FQuat::Slerp(Pivot.WorldTransform.Rotation, DestinationComp.FollowSplinePosition.WorldRotation, DeltaTime * 2.0));
			return;
		}

		FVector FocusLoc = Owner.FocusLocation;
		if (DestinationComp.Focus.IsValid())
			FocusLoc = DestinationComp.Focus.GetFocusLocation();
		else if (DestinationComp.HasDestination())
			FocusLoc = DestinationComp.Destination;	
		if (!FocusLoc.IsWithinDist(Owner.FocusLocation, 200))
		{
			FQuat FocusQuat = FQuat::MakeFromX(FocusLoc - Owner.FocusLocation);
	 		Pivot.SetWorldRotation(FQuat::Slerp(Pivot.WorldTransform.Rotation, FocusQuat, DeltaTime * 2.0));
		}
	}
}
