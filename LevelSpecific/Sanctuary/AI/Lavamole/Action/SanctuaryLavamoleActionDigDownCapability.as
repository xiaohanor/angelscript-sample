struct FSanctuaryLavamoleActionDigDownData
{

}

class USanctuaryLavamoleActionDigDownCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionDigDownData Params;
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);

	AAISanctuaryLavamole Mole;
	USanctuaryLavamoleSettings Settings;
	USanctuaryLavamoleDigComponent DigComp;
	
	FHazeAcceleratedVector AccDisappear;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		DigComp = USanctuaryLavamoleDigComponent::GetOrCreate(Owner);
		Mole = Cast<AAISanctuaryLavamole>(Owner);
		if(Mole != nullptr)
			Radius = Mole.CapsuleComponent.CapsuleRadius;	
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionDigDownData Parameters)
	{
		Params = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.DigDownDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Mole.AnimationMode = ESanctuaryLavamoleAnimation::Disappear;
		Mole.bIsUnderground = true;
		Mole.OccupiedHole.SetHoleCollisionEnabled(false);
		Mole.SetActorRotation(Mole.OriginalRotation);
		USanctuaryLavamoleEventHandler::Trigger_OnDigDown(Owner);
		FVector Diff = Mole.ActorLocation - Mole.OccupiedHole.ActorLocation;
		AccDisappear.SnapTo(Diff, FVector::ZeroVector);
		DigComp.DigDownStart();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DigComp.DigDownEnd();
		if (Mole.AnimationMode == ESanctuaryLavamoleAnimation::Disappear)
			Mole.AnimationMode = ESanctuaryLavamoleAnimation::IdleBelow;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// DestinationComp.RotateTowards(TargetComp.Target);
		AccDisappear.AccelerateTo(FVector(0,0,-500), Settings.DigDownDuration, DeltaTime);
		Mole.SetActorLocation(Mole.OccupiedHole.ActorLocation);
		// Mole.MeshOffsetComponent.RelativeLocation = AccDisappear.Value;
	}
}
