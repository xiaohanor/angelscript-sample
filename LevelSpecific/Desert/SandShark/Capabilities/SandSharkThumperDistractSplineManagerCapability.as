class USandSharkThumperDistractSplineManagerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(SandSharkTags::SandShark);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = SandShark::TickGroupOrder::ThumperDistract;

	ASandShark SandShark;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SandShark.GetQueuedDistractionSplines().Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SandShark.GetQueuedDistractionSplines().Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FSandSharkThumperDistractionParams Params;
		if (SandShark.GetQueuedDistractionParams(Params))
		{
			if (Time::GetGameTimeSince(Params.TimeWhenStarted) >= Params.DistractDuration)
			{
				SandShark.RemoveDistractionParamsFromQueue(Params);
			}
		}
	}
};