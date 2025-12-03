
class USummitCrystalSkullTrackTargetBehaviour : UBasicBehaviour
{
	// Rotation only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USummitCrystalSkullSettings FlyerSettings;
	USummitCrystalSkullComponent FlyerComp;
	UHazeOffsetComponent OffsetComp;
	FHazeAcceleratedRotator AccRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		OffsetComp = UHazeOffsetComponent::Get(Owner);		
		FlyerComp = USummitCrystalSkullComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccRot.SnapTo(OffsetComp.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.FocusLocation.IsWithinDist(TargetComp.Target.FocusLocation, FlyerSettings.TrackTargetRange))
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
		if (!Owner.FocusLocation.IsWithinDist(TargetComp.Target.FocusLocation, FlyerSettings.TrackTargetRange * 1.2))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (FlyerComp.bIsVulnerable)
			return;	

		// Pitch mesh towards target
		FRotator TargetRot = OffsetComp.WorldRotation;
		if (IsActive())
			TargetRot.Pitch = Math::ClampAngle((TargetComp.Target.ActorLocation - Owner.ActorLocation).Rotation().Pitch, -FlyerSettings.TrackTargetPitchClamp, FlyerSettings.TrackTargetPitchClamp);			
		else
			TargetRot.Pitch = 0.0;
		AccRot.AccelerateTo(TargetRot, FlyerSettings.TurnDuration, DeltaTime);
		FRotator NewRot = OffsetComp.WorldRotation;
		NewRot.Pitch = AccRot.Value.Pitch;
		OffsetComp.SetWorldRotation(NewRot);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (FlyerComp.bIsVulnerable)
		{
			DestinationComp.RotateInDirection(Owner.ActorForwardVector);
			return;
		}

		// Keep target in our sights
		DestinationComp.RotateTowards(TargetComp.Target);
	}
}
