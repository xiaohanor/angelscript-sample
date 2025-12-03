struct FSanctuaryLavamoleActionDigUpData
{
}

class USanctuaryLavamoleActionDigUpCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionDigUpData Params;
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);

	AAISanctuaryLavamole Mole;
	USanctuaryLavamoleSettings Settings;
	USanctuaryLavamoleDigComponent DigComp;
	
	FHazeAcceleratedVector AccAppear;
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
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionDigUpData Parameters)
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
		if (ActiveDuration > Settings.DigUpDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccAppear.Value = Mole.MeshOffsetComponent.RelativeLocation;
		USanctuaryLavamoleEventHandler::Trigger_OnDigUp(Owner);
		Mole.AnimationMode = ESanctuaryLavamoleAnimation::Appear;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Mole.MeshOffsetComponent.RelativeLocation = FVector::ZeroVector;
		Mole.bIsUnderground = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// DestinationComp.RotateTowards(TargetComp.Target);
		// AccAppear.AccelerateTo(FVector::ZeroVector, Settings.DigUpDuration, DeltaTime);
		// Mole.MeshOffsetComponent.RelativeLocation = AccAppear.Value;
	}
}
