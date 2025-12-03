struct FDentistSplitToothAirborneOnDeactivatedParams
{
	bool bIsLanding = false;
	FHitResult LandingImpact;
};

class UDentistSplitToothAirborneCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UHazeMovementComponent MoveComp;
	UDentistSplitToothComponent SplitToothComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		SplitToothComp = UDentistSplitToothComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SplitToothComp.bIsSplit)
			return false;

		if(!MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistSplitToothAirborneOnDeactivatedParams& Params) const
	{
		if(!SplitToothComp.bIsSplit)
			return true;

		if(!MoveComp.IsInAir())
		{
			Params.bIsLanding = true;
			Params.LandingImpact = MoveComp.GroundContact.ConvertToHitResult();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistSplitToothAirborneOnDeactivatedParams Params)
	{
		if(Params.bIsLanding)
		{
			FDentistSplitToothOnLandingEventData EventData;
			EventData.Impact = Params.LandingImpact;
			UDentistSplitToothEventHandler::Trigger_OnLanding(Owner, EventData);
			Print("Landing");
		}
	}
};