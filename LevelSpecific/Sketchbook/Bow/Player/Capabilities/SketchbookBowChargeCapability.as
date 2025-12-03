enum ESketchbookBowShootInput
{
    None,
    Fire,
    Queue
}

/**
 * 
 */
class USketchbookBowChargeCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = Sketchbook::Bow::DebugCategory;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Sketchbook::Bow::SketchbookBow);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	USketchbookBowPlayerComponent BowComp;
	USketchbookBowTrajectoryMeshComponent TrajectoryMeshComp;

    ESketchbookBowShootInput ShootInput = ESketchbookBowShootInput::None;

    bool bHasFullyCharged = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        BowComp = USketchbookBowPlayerComponent::Get(Player);
		TrajectoryMeshComp = USketchbookBowTrajectoryMeshComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if (ShootInput == ESketchbookBowShootInput::None)
			return false;

		if (DeactiveDuration < BowComp.BowSettings.ReloadTime)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(BowComp.bIsFiringBow)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		//Player.BlockCapabilities(WindJavelin::WindJavelinTag, this);
		Player.ApplyStrafeSpeedScale(this, 0.5);

		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(-5.0, this, 1);
		// Player.ApplyCameraOffset(FVector(0.0, -20.0, 0.0), float::Additive(0.5), this, EHazeCameraPriority::High);
        
		BowComp.SetChargeFactor(0.0);
		TrajectoryMeshComp.SetAlpha(0.0);
		BowComp.bIsChargingBow = true;

        USketchbookBowPlayerEventHandler::Trigger_StartDrawingBow(Player);

		// Force Feedback
        if(BowComp.BowSettings.ChargeForceFeedback != nullptr)
		{
            Player.PlayForceFeedback(BowComp.BowSettings.ChargeForceFeedback, false, false, this);
		}
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    { 
		Player.StopForceFeedback(this);
		TrajectoryMeshComp.SetAlpha(0.0);

		Player.ClearStrafeSpeedScale(this);

		Player.ClearCameraSettingsByInstigator(this, 0.5);
		BowComp.bIsChargingBow = false;

        if(ShootInput == ESketchbookBowShootInput::Queue)
            ShootInput = ESketchbookBowShootInput::Fire;
        else
            ShootInput = ESketchbookBowShootInput::None;
    }

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
        if(IsBlocked())
        {
            ShootInput = ESketchbookBowShootInput::None;
            return;
        }

        if(WasActionStarted(Sketchbook::Bow::ShootAction))
        {
            // If we are already set to fire (or are firing), queue up another shot
            if(BowComp.bIsFiringBow ||ShootInput == ESketchbookBowShootInput::Fire)
                ShootInput = ESketchbookBowShootInput::Queue;
            else
                ShootInput = ESketchbookBowShootInput::Fire;
        }
        else if(WasActionStopped(Sketchbook::Bow::ShootAction))
        {
            // If we stopped holding fire while firing, stop queueing shots
            if(BowComp.bIsFiringBow)
                ShootInput = ESketchbookBowShootInput::None;
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(!BowComp.AimComp.IsAiming(BowComp))
            return;

        if(!BowComp.IsFullyCharged())
        {
            bHasFullyCharged = false;
			const float Alpha = Math::Saturate(ActiveDuration / BowComp.BowSettings.ChargeTime);
            BowComp.SetChargeFactor(Alpha);
			TrajectoryMeshComp.SetAlpha(Alpha);

        }
        else if(!bHasFullyCharged)
        {
            USketchbookBowPlayerEventHandler::Trigger_FinishedCharging(Player);
            bHasFullyCharged = true;

			Player.PlayForceFeedback(BowComp.BowSettings.FullyChargedForceFeedback, false, true, this);
        }

        // Camera Shake
        if(BowComp.BowSettings.ChargeCameraShake != nullptr)
            Player.PlayCameraShake(BowComp.BowSettings.ChargeCameraShake, this, BowComp.GetChargeFactor());


	}
}