struct FSanctuaryLavamoleActionDigUpAnticipationData
{
}

class USanctuaryLavamoleActionDigUpAnticipationCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionDigUpAnticipationData Params;
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);
	UHazeActionQueueComponent ActionComp;

	AAISanctuaryLavamole Mole;
	USanctuaryLavamoleSettings Settings;
	USanctuaryLavamoleDigComponent DigComp;
	
	FHazeAcceleratedVector AccDisappear;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActionComp = UHazeActionQueueComponent::GetOrCreate(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		DigComp = USanctuaryLavamoleDigComponent::GetOrCreate(Owner);
		Mole = Cast<AAISanctuaryLavamole>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionDigUpAnticipationData Parameters)
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
		if (ActiveDuration > Settings.DigUpAnticipationDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DigComp.DigUpStart();
		// Mole.MeshOffsetComponent.RelativeLocation = FVector(0, 0, -500);
		USceneComponent HoleMeshComponent = Mole.OccupiedHole.Root;
		USanctuaryLavamoleEventHandler::Trigger_OnAnticipateUp(Owner, FSanctuaryLavamoleOnOnAnticipateUpEventData(HoleMeshComponent));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DigComp.DigUpEnd();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// bDigUpAnticipationActive = true;
		// DigUpAnticipationTimer = Settings.DigUpAnticipationDuration;
	}
}
