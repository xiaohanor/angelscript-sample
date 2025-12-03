enum EIceBowShootInput
{
    None,
    Fire,
    Queue
}

/**
 * 
 */
class UIceBowChargeCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = IceBow::DebugCategory;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(IceBow::IceBowTag);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	UIceBowPlayerComponent IceBowPlayerComp;

	// needs to activate after the aiming capability
	default TickGroupOrder = 106;

	default TickGroup = EHazeTickGroup::Movement;

    EIceBowShootInput ShootInput = EIceBowShootInput::None;

    bool bHasFullyCharged = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if (!IceBowPlayerComp.GetIsAiming())
			return false;

		if (ShootInput == EIceBowShootInput::None)
			return false;

		if (DeactiveDuration < IceBowPlayerComp.BowSettings.ReloadTime)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(!IsActioning(IceBow::AimAction))
            return true;

		if(IceBowPlayerComp.bIsFiringIceBow)
			return true;

		if(!IceBowPlayerComp.bIsChargingIceBow)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		Player.BlockCapabilities(WindJavelin::WindJavelinTag, this);
		Player.ApplyStrafeSpeedScale(this, 0.5);

		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(-5.0, this, 1);
		// Player.ApplyCameraOffset(FVector(0.0, -20.0, 0.0), float::Additive(0.5), this, EHazeCameraPriority::High);
        
		IceBowPlayerComp.SetChargeFactor(0.0);
		IceBowPlayerComp.bIsChargingIceBow = true;

        UIceBowEventHandler::Trigger_StartDrawingBow(Player);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    { 
		Player.UnblockCapabilities(WindJavelin::WindJavelinTag, this);

		Player.ClearStrafeSpeedScale(this);

		Player.ClearCameraSettingsByInstigator(this, 0.5);
		IceBowPlayerComp.bIsChargingIceBow = false;

        if(ShootInput == EIceBowShootInput::Queue)
            ShootInput = EIceBowShootInput::Fire;
        else
            ShootInput = EIceBowShootInput::None;
    }

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
        if(IsBlocked())
        {
            ShootInput = EIceBowShootInput::None;
            return;
        }

        if(!IceBowPlayerComp.GetIsAiming())
        {
            ShootInput = EIceBowShootInput::None;
			return;
        }

        if(WasActionStarted(IceBow::ShotAction))
        {
            // If we are already set to fire (or are firing), queue up another shot
            if(IceBowPlayerComp.bIsFiringIceBow ||ShootInput == EIceBowShootInput::Fire)
                ShootInput = EIceBowShootInput::Queue;
            else
                ShootInput = EIceBowShootInput::Fire;
        }
        else if(WasActionStopped(IceBow::ShotAction))
        {
            // If we stopped holding fire while firing, stop queueing shots
            if(IceBowPlayerComp.bIsFiringIceBow)
                ShootInput = EIceBowShootInput::None;
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!IceBowPlayerComp.AimComp.IsAiming(IceBowPlayerComp))
            return;

        if(!IceBowPlayerComp.IsFullyCharged())
        {
            bHasFullyCharged = false;
            IceBowPlayerComp.SetChargeFactor(Math::Saturate(ActiveDuration / BowSettings.ChargeTime));
        }
        else if(!bHasFullyCharged)
        {
            UIceBowEventHandler::Trigger_FinishedCharging(Player);
            bHasFullyCharged = true;

			Player.PlayForceFeedback(BowSettings.FullyChargedForceFeedback, false, true, this);
        }

		// Updated aim result since player can still move aim while waiting to shoot
        FAimingResult AimResult = IceBowPlayerComp.AimComp.GetAimingTarget(IceBowPlayerComp);
        Player.SetMovementFacingDirection(AimResult.AimDirection.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal());

        // Camera Shake
        if(BowSettings.ChargeCameraShake != nullptr)
            Player.PlayCameraShake(BowSettings.ChargeCameraShake, this, IceBowPlayerComp.GetChargeFactor());

        // Force Feedback
        if(BowSettings.ChargeForceFeedback != nullptr)
            Player.PlayForceFeedback(BowSettings.ChargeForceFeedback, true, false, this, IceBowPlayerComp.GetChargeFactor());
	}

	UIceBowSettings GetBowSettings() const property
	{
		return IceBowPlayerComp.BowSettings;
	}
}