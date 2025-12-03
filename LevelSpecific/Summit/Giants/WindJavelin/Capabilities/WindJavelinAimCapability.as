/**
 * 
 */
class UWindJavelinAimCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = WindJavelin::DebugCategory;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(WindJavelin::WindJavelinTag);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	UWindJavelinPlayerComponent PlayerComp;

	// needs to activate before the throwing capability
	default TickGroupOrder = 106;
	default TickGroup = EHazeTickGroup::Movement;

	float LastAimTime = 0.0;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UWindJavelinPlayerComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(!PlayerComp.GetIsUsingWindJavelin())
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(PlayerComp.GetIsUsingWindJavelin())
            return false;

        // if(LastAimTime > Time::GameTimeSeconds - PlayerComp.Settings.AimAfterThrowDelay)
        //     return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        // Block IceBow while using WindJavelin
		Player.BlockCapabilities(IceBow::IceBowTag, this);

        Player.BlockCapabilities(PlayerMovementTags::WallRun, this);
        Player.BlockCapabilities(PlayerMovementTags::LedgeGrab, this);
        Player.BlockCapabilities(PlayerMovementTags::WallScramble, this);

        PlayerComp.AimComp.StartAiming(PlayerComp, PlayerComp.Settings.AimSettings);
        Player.ApplyCameraSettings(PlayerComp.Settings.CamSettings, float(0.5), this, SubPriority = 61);
        Player.SetStrafeYawOffset(PlayerComp.Settings.StrafeYawOffset);
        Player.SetStrafeKeepOrientationInMh(false);
        Player.EnableStrafe(this);

        UWindJavelinEventHandler::Trigger_StartAiming(Player);

		LastAimTime = Time::GameTimeSeconds;

		// PlayerComp.WindParams.set
		Material::SetScalarParameterValue(PlayerComp.WindParams, n"GlobalWindStrength", 1.0);
		Material::SetScalarParameterValue(PlayerComp.WindParams, n"GlobalWindGusts", 1.0);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		Player.UnblockCapabilities(IceBow::IceBowTag, this);

        Player.UnblockCapabilities(PlayerMovementTags::WallRun, this);
        Player.UnblockCapabilities(PlayerMovementTags::LedgeGrab, this);
        Player.UnblockCapabilities(PlayerMovementTags::WallScramble, this);

        PlayerComp.AimComp.StopAiming(PlayerComp);
        Player.ClearCameraSettingsByInstigator(this, 0.5);
        Player.SetStrafeYawOffset(0.0);
        Player.SetStrafeKeepOrientationInMh(true);
        Player.DisableStrafe(this);

        UWindJavelinEventHandler::Trigger_StopAiming(Player);

		LastAimTime = 0.0;

		if (PlayerComp.WindJavelin != nullptr)
        {
            PlayerComp.WindJavelin.DestroyActor();
            PlayerComp.WindJavelin = nullptr;
        }

		Material::SetScalarParameterValue(PlayerComp.WindParams, n"GlobalWindStrength", 0.1);
		Material::SetScalarParameterValue(PlayerComp.WindParams, n"GlobalWindGusts", 0.1);

		ClearAimAtResponseComponent();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(PlayerComp.GetIsAiming())
			FindAimAtResponseComponent();
		else
			ClearAimAtResponseComponent();

		if(PlayerComp.GetIsUsingWindJavelin())
        {
			LastAimTime = Time::GameTimeSeconds;
            //Player.SetStrafeYawOffset(PlayerComp.Settings.StrafeYawOffset);
            //Player.SetStrafeKeepOrientationInMh(false);
        }
        else
        {
            //Player.SetStrafeYawOffset(0.0);
        }
    }

	private void FindAimAtResponseComponent()
	{
		UWindJavelinResponseComponent NewAimAtResponseComponent;
		FAimingResult AimResult = PlayerComp.AimComp.GetAimingTarget(PlayerComp);
		if(AimResult.AutoAimTarget != nullptr)
		{
			NewAimAtResponseComponent = UWindJavelinResponseComponent::Get(AimResult.AutoAimTarget.Owner);
		}
		else
		{
			FHitResult Hit = PlayerComp.TraceForTarget();
			if(Hit.bBlockingHit)
				NewAimAtResponseComponent = UWindJavelinResponseComponent::Get(Hit.Actor);
		}

		if(NewAimAtResponseComponent != nullptr)
		{
			if(NewAimAtResponseComponent == PlayerComp.AimAtResponseComponent)
				return;

			if(PlayerComp.AimAtResponseComponent != nullptr)
				ClearAimAtResponseComponent();

			PlayerComp.AimAtResponseComponent = NewAimAtResponseComponent;
			PlayerComp.AimAtResponseComponent.StartBeingAimedAt();
		}
		else if(PlayerComp.AimAtResponseComponent != nullptr)
		{
			ClearAimAtResponseComponent();
		}
	}

	private void ClearAimAtResponseComponent()
	{
		if(PlayerComp.AimAtResponseComponent == nullptr)
			return;

		PlayerComp.AimAtResponseComponent.StopBeingAimedAt();
		PlayerComp.AimAtResponseComponent = nullptr;
	}
}