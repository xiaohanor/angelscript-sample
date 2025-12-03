/**
 * 
 */
class UIceBowAimCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = IceBow::DebugCategory;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(IceBow::IceBowTag);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::DashRollState);

	UIceBowPlayerComponent IceBowPlayerComp;

	// needs to activate before the shooting capability
	default TickGroupOrder = 105;

	default TickGroup = EHazeTickGroup::Movement;

    float AimDelay = 0.5;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(IceBowPlayerComp.AimComp.IsAiming(IceBowPlayerComp))
            return false;

        if(!IsActioning(IceBow::AimAction))
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(IceBowPlayerComp.GetIsCharging())
			return false;

		if(IsActioning(IceBow::AimAction))
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		Player.BlockCapabilities(WindJavelin::WindJavelinTag, this);

        Player.BlockCapabilities(PlayerMovementTags::WallRun, this);
        Player.BlockCapabilities(PlayerMovementTags::LedgeGrab, this);
        Player.BlockCapabilities(PlayerMovementTags::WallScramble, this);

        IceBowPlayerComp.AimComp.StartAiming(IceBowPlayerComp, IceBowPlayerComp.BowSettings.AimSettings);
        Player.ApplyCameraSettings(IceBowPlayerComp.BowSettings.CamSettings, 0.5, this, SubPriority = 61);
        Player.EnableStrafe(this);
        Player.SetStrafeYawOffset(BowSettings.StrafeYawOffset);
        Player.SetStrafeKeepOrientationInMh(false);

        UIceBowEventHandler::Trigger_StartAiming(Player);

        IceBowPlayerComp.bIsAimingIceBow = true;

		Material::SetScalarParameterValue(IceBowPlayerComp.WindParams, n"GlobalWindStrength", 1.0);
		Material::SetScalarParameterValue(IceBowPlayerComp.WindParams, n"GlobalWindGusts", 1.0);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		Player.UnblockCapabilities(WindJavelin::WindJavelinTag, this);
		
        Player.UnblockCapabilities(PlayerMovementTags::WallRun, this);
        Player.UnblockCapabilities(PlayerMovementTags::LedgeGrab, this);
        Player.UnblockCapabilities(PlayerMovementTags::WallScramble, this);

        IceBowPlayerComp.AimComp.StopAiming(IceBowPlayerComp);
        Player.ClearCameraSettingsByInstigator(this, 0.5);
        Player.DisableStrafe(this);
        Player.SetStrafeYawOffset(0.0);
        Player.SetStrafeKeepOrientationInMh(true);

        UIceBowEventHandler::Trigger_StopAiming(Player);
		
        IceBowPlayerComp.bIsAimingIceBow = false;
        IceBowPlayerComp.SetChargeFactor(0.0);

		Material::SetScalarParameterValue(IceBowPlayerComp.WindParams, n"GlobalWindStrength", 0.1);
		Material::SetScalarParameterValue(IceBowPlayerComp.WindParams, n"GlobalWindGusts", 0.1);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(!Player.Mesh.CanRequestOverrideFeature())
            return;

        Player.Mesh.RequestOverrideFeature(IceBow::Feature, this);
    }

    UIceBowSettings GetBowSettings() const property
    {
        return IceBowPlayerComp.BowSettings;
    }
}