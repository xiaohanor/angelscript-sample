
class UPrisonGuardTrackTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UPrisonGuardAnimationComponent GuardAnimComp;
	UPrisonGuardSettings Settings;
	AHazeActor Target;
	UHazeSkeletalMeshComponentBase Mesh;
	bool bSpineTracking;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GuardAnimComp = UPrisonGuardAnimationComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		Settings = UPrisonGuardSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() )
			GuardAnimComp.AccSpineYaw.AccelerateTo(0.0, 0.5, DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.FocusLocation.IsWithinDist(TargetComp.Target.FocusLocation, Settings.TrackTargetRange))
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
		if (!Owner.FocusLocation.IsWithinDist(TargetComp.Target.FocusLocation, Settings.TrackTargetRange + 500.0))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		bSpineTracking = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TargetComp.HasValidTarget())
			Target = TargetComp.Target;

		// Keep target in our sights
		DestinationComp.RotateTowards(Target);

		if (!bSpineTracking && Owner.FocusLocation.IsWithinDist(Target.FocusLocation, Settings.SpineTrackTargetRange))
			bSpineTracking = true;
		else if (bSpineTracking && !Owner.FocusLocation.IsWithinDist(Target.FocusLocation, Settings.SpineTrackTargetRange + 500.0))
			bSpineTracking = false;

		if (bSpineTracking)
			GuardAnimComp.AccSpineYaw.AccelerateTo(GuardAnimComp.GetSpineYawTo(Mesh, Target.FocusLocation, Settings.SpineTrackTargetMaxYaw), 0.5, DeltaTime);
		else
			GuardAnimComp.AccSpineYaw.AccelerateTo(0.0, 1.0, DeltaTime);
	}
}
