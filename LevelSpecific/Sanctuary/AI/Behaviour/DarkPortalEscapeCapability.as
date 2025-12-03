class UDarkPortalEscapeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UDarkPortalResponseComponent DarkPortalComp;
	UDarkPortalTargetComponent DarkPortalTargetComp;
	USanctuaryReactionSettings ReactionSettings;

	bool bDisabledTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DarkPortalComp = UDarkPortalResponseComponent::Get(Owner);	
		DarkPortalTargetComp = UDarkPortalTargetComponent::Get(Owner);	
		ReactionSettings = USanctuaryReactionSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ReactionSettings.MaxGrabDuration <= 0)
			return false;

		if (!DarkPortalComp.IsGrabbed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > ReactionSettings.MaxGrabDuration + ReactionSettings.ImmuneGrabDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bDisabledTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		EnableTarget();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDisabledTarget || ActiveDuration < ReactionSettings.MaxGrabDuration)
			return;

		bDisabledTarget = true;
		for (int i = DarkPortalComp.Grabs.Num()-1; i >= 0; i--)
		{
			FDarkPortalResponseGrab Grab = DarkPortalComp.Grabs[i];
			Grab.Portal.Release(Grab.TargetComponent);
		}
		DisableTarget();
	}

	private void EnableTarget()
	{
		DarkPortalTargetComp.Enable(this);
	}

	private void DisableTarget()
	{
		DarkPortalTargetComp.Disable(this);
	}
}