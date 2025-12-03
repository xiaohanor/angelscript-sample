/**
 * 
 */
class UWindJavelinChargeCapability : UHazePlayerCapability
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
	default TickGroupOrder = 105;
	default TickGroup = EHazeTickGroup::Movement;

    UPlayerMovementComponent MoveComp;
    USteppingMovementData Movement;

    bool bWasBlocked = false;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UWindJavelinPlayerComponent::Get(Player);

        MoveComp = UPlayerMovementComponent::Get(Player);
        Movement = MoveComp.SetupSteppingMovementData();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(!bWasBlocked && (DeactiveDuration < Settings.ReloadTime && Time::GameTimeSeconds > Settings.ReloadTime))
            return false;

		if (!WasActionStarted(WindJavelin::ThrowAction))
			return false;

		if(PlayerComp.GetIsThrowing())
            return false;

        if(PlayerComp.WindJavelin != nullptr)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(IsActioning(IceBow::AimAction))
            return true;

        if(IsActioning(WindJavelin::ThrowAction))
            return false;

        if (!PlayerComp.bIsThrowing)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
        if(IsBlocked())
            bWasBlocked = true;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		Player.BlockCapabilities(IceBow::IceBowTag, this);
        UWindJavelinEventHandler::Trigger_StartCharging(Player);
        PlayerComp.bIsAiming = true;
        bWasBlocked = false;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		Player.UnblockCapabilities(IceBow::IceBowTag, this);
        PlayerComp.bIsAiming = false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(ActiveDuration > Settings.SpawnJavelinDelay && PlayerComp.WindJavelin == nullptr)
            PlayerComp.bSpawn = true;

        if(Player.Mesh.CanRequestOverrideFeature())
            Player.Mesh.RequestOverrideFeature(WindJavelin::Feature, this);

        // Camera Shake
        if(Settings.ChargeCameraShake != nullptr)
            Player.PlayCameraShake(Settings.ChargeCameraShake, this, PlayerComp.GetChargeFactor());

        // Force Feedback
        if(Settings.ChargeForceFeedback != nullptr)
            Player.PlayForceFeedback(Settings.ChargeForceFeedback, true, false, this, PlayerComp.GetChargeFactor());

        PlayerComp.AimDuration = Math::Max(0.0, ActiveDuration - Settings.StartChargingDelay);
    }

    UWindJavelinSettings GetSettings() const property
    {
        return PlayerComp.Settings;
    }
}