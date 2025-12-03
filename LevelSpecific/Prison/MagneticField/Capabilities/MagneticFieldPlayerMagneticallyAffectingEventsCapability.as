struct FMagneticFieldPlayerMagneticallyAffectingEventsActivateParams
{
	FMagneticFieldNearbyData CurrentNearbyData;
};

class UMagneticFieldPlayerMagneticallyAffectingEventsCapability : UHazePlayerCapability
{
	// No need to be crumbed since we query nearby objects on both Control and Remote
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UMagneticFieldPlayerComponent MagneticFieldComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagneticFieldComp = UMagneticFieldPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagneticFieldPlayerMagneticallyAffectingEventsActivateParams& Params) const
	{
		if(MagneticFieldComp.CurrentNearbyDataFrame != Time::FrameNumber)
			return false;

		if(MagneticFieldComp.CurrentNearbyData.NearbyCount == 0)
			return false;

		Params.CurrentNearbyData = MagneticFieldComp.CurrentNearbyData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MagneticFieldComp.CurrentNearbyDataFrame != Time::FrameNumber)
			return true;

		if(MagneticFieldComp.CurrentNearbyData.NearbyCount == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagneticFieldPlayerMagneticallyAffectingEventsActivateParams Params)
	{
		UMagneticFieldEventHandler::Trigger_StartedMagneticallyAffecting(Player, Params.CurrentNearbyData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMagneticFieldEventHandler::Trigger_StoppedMagneticallyAffecting(Player);
	}
};