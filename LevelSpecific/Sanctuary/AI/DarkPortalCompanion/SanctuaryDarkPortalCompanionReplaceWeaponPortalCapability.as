class USanctuaryDarkPortalCompanionReplaceWeaponPortalCapability : UHazeCapability
{	
	default CapabilityTags.Add(n"Companion");

	USanctuaryDarkPortalCompanionComponent CompanionComp;
	USanctuaryDarkPortalCompanionSettings Settings;
	bool bHidingPortal = false;
	float HideCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CompanionComp = USanctuaryDarkPortalCompanionComponent::GetOrCreate(Owner); 
		Settings = USanctuaryDarkPortalCompanionSettings::GetSettings(Owner); 
		HideCompanion();
		CompanionComp.Portal.AddActorVisualsBlock(this);
		bHidingPortal = true;
	}

	bool ShouldShowPortal() const
	{
		ADarkPortalActor Portal = CompanionComp.Portal;
		if (Portal.bIsGrabActive)
		 	return true;

		if (Portal.bForcedVisible)
			return true;

		if (Portal.State == EDarkPortalState::Settle)
		{
			// Always allow for a minimum time to settle
			if (Time::GetGameTimeSince(Portal.StateTimestamp) < Settings.CompanionMinSettleDuration)
				return true; 

			// Hide when too far away
			if (!Portal.ActorLocation.IsWithinDist(Portal.Player.ActorLocation, Settings.AutoRecallRange))
				return false;

			// Keep portal in place when there's stuff to grab
			if (HasGrabbables(Portal))
				return true;	

			// No time limit to how long portal may remain inactive
			return true;
		}

		return false;
	}

	bool HasGrabbables(ADarkPortalActor Portal) const
	{
		// TODO
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Companion is always active (unless blocked) but will at times show portal 
		return (CompanionComp.Portal != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CompanionComp.bReplaceWeaponPortal = true;

		Owner.RemoveActorVisualsBlock(this);
		Owner.RemoveActorCollisionBlock(this);
		Owner.SetActorVelocity(FVector::ZeroVector);

		bHidingPortal = true;
		HideCooldown = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HideCompanion();
		if (bHidingPortal)
			CompanionComp.Portal.RemoveActorVisualsBlock(this);
		bHidingPortal = false;
	}

	void HideCompanion()
	{
		CompanionComp.bReplaceWeaponPortal = false;
		Owner.AddActorVisualsBlock(this);
		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (ShouldShowPortal())
		{
			if (bHidingPortal)
				CrumbShowPortal();
		}
		else if (!bHidingPortal && (ActiveDuration > HideCooldown))
		{
			CrumbHidePortal(CompanionComp.Portal.State == EDarkPortalState::Settle);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbShowPortal()
	{
		CompanionComp.Portal.RemoveActorVisualsBlock(this);
		bHidingPortal = false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbHidePortal(bool bRecall)
	{
		if (bRecall)
			CompanionComp.Portal.InstantRecall();	
		CompanionComp.Portal.AddActorVisualsBlock(this);
		bHidingPortal = true;
		HideCooldown = ActiveDuration + 0.2;
	}
}
