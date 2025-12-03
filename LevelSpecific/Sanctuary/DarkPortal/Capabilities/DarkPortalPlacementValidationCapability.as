class UDarkPortalPlacementValidationCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalPlacementValidation);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADarkPortalActor Portal;
	AHazePlayerCharacter Player;
	UDarkPortalUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Portal = Cast<ADarkPortalActor>(Owner);
		Player = Portal.Player;
		UserComp = UDarkPortalUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Portal.IsSettled())
		{
			if (!Portal.IsAttachValid())
				return true;

			if (Portal.bDespawnRequested)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Portal.PushAndReleaseAll();
		Portal.InstantRecall();
		Portal.bDespawnRequested = false;
	}
}