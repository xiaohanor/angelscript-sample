
class UBasicTrackTargetBehaviour : UBasicBehaviour
{
	// Rotation only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	float LostVisibilityDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.FocusLocation.IsWithinDist(TargetComp.Target.FocusLocation, BasicSettings.TrackTargetRange))
			return false;
		if (BasicSettings.bTrackTargetsRequireVisibility && !TargetComp.HasVisibleTarget())
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
		if (!Owner.FocusLocation.IsWithinDist(TargetComp.Target.FocusLocation, BasicSettings.TrackTargetRange + 500.0))
			return true;
		if (LostVisibilityDuration > 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Keep target in our sights
		DestinationComp.RotateTowards(TargetComp.Target);

		if (BasicSettings.bTrackTargetsRequireVisibility) 
			LostVisibilityDuration = TargetComp.HasVisibleTarget() ? 0.0 : LostVisibilityDuration + DeltaTime;
	}
}
