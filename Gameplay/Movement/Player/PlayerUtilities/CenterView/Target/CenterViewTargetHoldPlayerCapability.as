struct FCenterViewTargetHoldActivateParams
{
	FCenterViewTarget CenterViewTarget;
};

/**
 * Handles locking on to a Center View Target.
 * Is not blocked by CameraControl, since this should still be active even when the camera
 * is grabbed by something else, so that the center view rotation can be continued later.
 */
class UCenterViewTargetHoldPlayerCapability : UHazePlayerCapability
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

	float HoldInputDuration = -1;
	float LastInputTime = -1;
	bool bWantsToDisengage = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
		CenterViewSettings = UCenterViewSettings::GetSettings(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCenterViewTargetHoldActivateParams& Params) const
	{
		if(!CenterViewComp.CanApplyCenterView())
			return false;

		if(CenterViewSettings.LockViewTarget != ECenterViewLockViewTarget::Hold)
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
		if(CenterViewComp.TryGetForcedTarget(ForcedTarget))
		{
			if(!ForcedTarget.Params.bRequireInputToActivate)
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

		if(CenterViewSettings.LockViewTarget != ECenterViewLockViewTarget::Hold)
			return true;

		if(!CenterViewComp.CurrentCenterViewTarget.IsSet())
			return true;

		// The target has become invalid
		if(!IsValid(CenterViewComp.CurrentCenterViewTarget.Value.Target))
			return true;

		if(CenterViewComp.CurrentCenterViewTarget.Value.bIsForcedTarget)
		{
			FCenterViewForcedTarget ForcedTarget;
			if(CenterViewComp.TryGetForcedTarget(ForcedTarget))
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

		if(HoldInputDuration < 0 && Time::GetRealTimeSince(LastInputTime) < CenterViewSettings.MinimumLockOnDuration)
			return false;

		const bool bHasPassedDisengageFromInputDelay = Time::GetRealTimeSince(CenterViewComp.StartCenteringTargetRealTime) > CenterViewSettings.DisengageFromInputDelay;
		if(bHasPassedDisengageFromInputDelay)
		{
			if(bWantsToDisengage)
				return true;

			// Disengage if no longer holding
			if(!IsActioning(ActionNames::CenterView))
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
	void OnActivated(FCenterViewTargetHoldActivateParams Params)
	{
		CenterViewComp.CurrentCenterViewTarget.Set(Params.CenterViewTarget);

		HoldInputDuration = 0;
		LastInputTime = Time::RealTimeSeconds;
		bWantsToDisengage = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CenterViewComp.OnCenterViewDeactivated();
		HoldInputDuration = -1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(IsActioning(ActionNames::CenterView) && HoldInputDuration >= 0)
		{
			HoldInputDuration += Time::GetCameraDeltaSeconds(true);
			LastInputTime = Time::RealTimeSeconds;
		}
		else
		{
			HoldInputDuration = -1;
		}

		if(HoldInputDuration < 0)
		{
			if(WasActionStarted(ActionNames::CenterView))
				bWantsToDisengage = true;
		}
	}
};