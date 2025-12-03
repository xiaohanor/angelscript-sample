struct FCenterViewTargetToggleActivateParams
{
	FCenterViewTarget CenterViewTarget;
};

struct FCenterViewTargetToggleDeactivateParams
{
	bool bFromInput = false;
};

/**
 * Handles locking on to a Center View Target.
 * Is not blocked by CameraControl, since this should still be active even when the camera
 * is grabbed by something else, so that the center view rotation can be continued later.
 */
class UCenterViewTargetTogglePlayerCapability : UHazePlayerCapability
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
	bool bWantsToDisengage = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CenterViewComp = UCenterViewPlayerComponent::Get(Player);
		CenterViewSettings = UCenterViewSettings::GetSettings(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCenterViewTargetToggleActivateParams& Params) const
	{
		if(!CenterViewComp.CanApplyCenterView())
			return false;

		if(CenterViewSettings.LockViewTarget != ECenterViewLockViewTarget::Toggle)
			return false;

		// We can stay active while CenterViewRotation is blocked, but we can't activate while it is blocked
		if(Player.IsCapabilityTagBlocked(CameraTags::CenterViewRotation))
			return false;

		bool bWantsToFocus = false;

		if (WasActionStarted(ActionNames::CenterView))
			bWantsToFocus = true;
		
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
	bool ShouldDeactivate(FCenterViewTargetToggleDeactivateParams& Params) const
	{
		if(!CenterViewComp.CanApplyCenterView())
			return true;

		if(CenterViewSettings.LockViewTarget != ECenterViewLockViewTarget::Toggle)
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

		bool bCanDisengageFromInput = true;

		if(!CenterViewComp.CurrentCenterViewTarget.Value.bAllowCenterViewInputToDeactivate)
			bCanDisengageFromInput = false;
		
		if(bCanDisengageFromInput)
		{
			const bool bHasPassedDisengageFromInputDelay = Time::GetRealTimeSince(CenterViewComp.StartCenteringTargetRealTime) > CenterViewSettings.DisengageFromInputDelay;
			if(bHasPassedDisengageFromInputDelay)
			{
				if(bWantsToDisengage)
				{
					Params.bFromInput = true;
					return true;
				}

				// Disengage if input tapped again
				// FB TODO: Check during input delay as well?
				if(WasActionStarted(ActionNames::CenterView))
				{
					Params.bFromInput = true;
					return true;
				}

				if(CenterViewSettings.bDisengageIfReleaseAfterHoldDuringToggle && HoldInputDuration > CenterViewSettings.DisengageFromInputDelay)
				{
					// If we started this toggle by holding down the button for some time, disengage when it is released
					if(!IsActioning(ActionNames::CenterView))
					{
						Params.bFromInput = true;
						return true;
					}
				}
			}
		}

		const bool bShouldHaveReachedTarget = CenterViewComp.ShouldHaveReachedTarget(false);
		if(bShouldHaveReachedTarget)
		{
			bool bCanDisengageFromCameraInput = true;

			FCenterViewForcedTarget ForcedTarget;
			if(CenterViewComp.TryGetForcedTarget(ForcedTarget))
			{
				bCanDisengageFromCameraInput = ForcedTarget.Params.bAllowCameraInputToDeactivate;
			}
			else if(!CenterViewSettings.bDisengageFromCameraInput)
			{
				bCanDisengageFromCameraInput = false;
			}

			if(bCanDisengageFromCameraInput)
			{
				// If giving camera input, disable
				if(!GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
					return true;
			}
		}

		TArray<UTargetableComponent> AllTargets;
		TargetablesComp.GetVisibleTargetables(UCenterViewTargetComponent, AllTargets);

		// The target is no longer visible
		if(!AllTargets.Contains(CenterViewComp.CurrentCenterViewTarget.Value.Target))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCenterViewTargetToggleActivateParams Params)
	{
		CenterViewComp.CurrentCenterViewTarget.Set(Params.CenterViewTarget);

		HoldInputDuration = 0;
		bWantsToDisengage = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCenterViewTargetToggleDeactivateParams Params)
	{
		if(Params.bFromInput)
			Player.ConsumeButtonInputsRelatedTo(ActionNames::CenterView);

		CenterViewComp.OnCenterViewDeactivated();
		HoldInputDuration = -1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(IsActioning(ActionNames::CenterView) && HoldInputDuration >= 0)
		{
			HoldInputDuration += Time::GetCameraDeltaSeconds(true);
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