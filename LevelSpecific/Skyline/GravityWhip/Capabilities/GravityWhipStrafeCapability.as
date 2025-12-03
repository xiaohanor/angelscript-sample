class UGravityWhipStrafeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipStrafe);

	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 150;

	UGravityWhipUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AimComp.HasAiming2DConstraint())
			return false;

		if (!UserComp.IsGrabbingAny())
		{
			if (!UserComp.bIsAirGrabbing)
				return false;
		}
		else
		{
			if (UserComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::GloryKill)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AimComp.HasAiming2DConstraint())
			return true;

		if (!UserComp.IsGrabbingAny())
		{
			if (!UserComp.bIsAirGrabbing)
			{
				float TimeSinceRelease = Time::GetGameTimeSince(UserComp.ReleaseTimestamp);
				if (TimeSinceRelease > GravityWhip::Grab::StrafeDuration)
					return true;
				if (UserComp.bReleaseStrafeImmediately)
					return true;
			}
		}
		else
		{
			if (UserComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::GloryKill)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.EnableStrafe(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DisableStrafe(this);
	}
}