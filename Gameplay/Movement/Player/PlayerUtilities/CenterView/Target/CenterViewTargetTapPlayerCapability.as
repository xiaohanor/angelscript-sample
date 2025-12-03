struct FCenterViewTargetTapActivateParams
{
	FCenterViewTarget CenterViewTarget;
};

/**
 * Handles locking on to a Center View Target.
 * Is not blocked by CameraControl, since this should still be active even when the camera
 * is grabbed by something else, so that the center view rotation can be continued later.
 */
class UCenterViewTargetTapPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CapabilityTags::CenterView);
	default CapabilityTags.Add(CameraTags::CenterViewTarget);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UCenterViewPlayerComponent CenterViewComp;
	UCenterViewSettings CenterViewSettings;
	UPlayerTargetablesComponent TargetablesComp;

	float LastInputTime = -1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
		CenterViewSettings = UCenterViewSettings::GetSettings(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCenterViewTargetTapActivateParams& Params) const
	{
		if(!CenterViewComp.CanApplyCenterView())
			return false;

		if(CenterViewSettings.LockViewTarget != ECenterViewLockViewTarget::NoLock)
			return false;

		// We can stay active while CenterViewRotation is blocked, but we can't activate while it is blocked
		if(Player.IsCapabilityTagBlocked(CameraTags::CenterViewRotation))
			return false;

		bool bWantsToFocus = false;

		if (WasActionStarted(ActionNames::CenterView))
		{
			bWantsToFocus = true;
		}
		
		FCenterViewForcedTarget ForcedTarget;
		if(CenterViewComp.TryGetForcedTarget(ForcedTarget) && !ForcedTarget.Params.bRequireInputToActivate)
		{
			bWantsToFocus = true;
		}

		if(!bWantsToFocus)
			return false;

		FCenterViewTarget CenterViewTarget;
		if(ForcedTarget.IsValid())
			CenterViewTarget = FCenterViewTarget(ForcedTarget);
		else
			CenterViewTarget.Target = TargetablesComp.GetPrimaryTarget(UCenterViewTargetComponent);

		if(CenterViewTarget.Target == nullptr)
			return false;

		Params.CenterViewTarget = CenterViewTarget;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CenterViewComp.CanApplyCenterView())
			return true;

		if(CenterViewSettings.LockViewTarget != ECenterViewLockViewTarget::NoLock)
			return true;

		if(!CenterViewComp.CurrentCenterViewTarget.IsSet())
			return true;

		// The target has become invalid
		if(!IsValid(CenterViewComp.CurrentCenterViewTarget.Value.Target))
			return true;

		if(CenterViewComp.CurrentCenterViewTarget.Value.bIsForcedTarget)
		{
			FCenterViewForcedTarget ForcedTarget;
			if(!CenterViewComp.TryGetForcedTarget(ForcedTarget))
			{
				// Forced target lost
				return true;
			}
			else if(CenterViewComp.CurrentCenterViewTarget.Value.Target != ForcedTarget.Target)
			{
				// Forced target changed
				return true;
			}
		}

		if(Time::GetRealTimeSince(LastInputTime) < CenterViewSettings.MinimumLockOnDuration)
			return false;

		const bool bHasPassedDisengageFromInputDelay = Time::GetRealTimeSince(CenterViewComp.StartCenteringTargetRealTime) > CenterViewSettings.DisengageFromInputDelay;
		if(bHasPassedDisengageFromInputDelay)
		{
			// Disengage the next frame, since we are not locking
			return true;
		}

		TArray<UTargetableComponent> AllTargets;
		TargetablesComp.GetVisibleTargetables(UCenterViewTargetComponent, AllTargets);

		// The target is no longer visible
		if(!AllTargets.Contains(CenterViewComp.CurrentCenterViewTarget.Value.Target))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCenterViewTargetTapActivateParams Params)
	{
		CenterViewComp.CurrentCenterViewTarget.Set(Params.CenterViewTarget);

		LastInputTime = Time::RealTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CenterViewComp.OnCenterViewDeactivated();
	}
};