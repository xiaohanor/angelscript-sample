struct FWindJavelinThrowOnActivatedParams
{
    FVector ThrowVelocity;
}

/**
 * 
 */
class UWindJavelinThrowCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = WindJavelin::DebugCategory;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
    default CapabilityTags.Add(WindJavelin::WindJavelinTag);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);

	default TickGroupOrder = 107;
	default TickGroup = EHazeTickGroup::Movement;

	UWindJavelinPlayerComponent PlayerComp;

    UPlayerMovementComponent MoveComp;
    USweepingMovementData Movement;

	UProjectileProximityManagerComponent ProjectileProximityComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UWindJavelinPlayerComponent::Get(Player);
        MoveComp = UPlayerMovementComponent::Get(Player);
        Movement = MoveComp.SetupSweepingMovementData();
		ProjectileProximityComp = UProjectileProximityManagerComponent::GetOrCreate(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate(FWindJavelinThrowOnActivatedParams& Params) const
    {
        if (PlayerComp.WindJavelin == nullptr)
            return false;

        if (!PlayerComp.bThrow)
            return false;

        FWindJavelinTargetData TargetData = PlayerComp.CalculateTargetData();
        Params.ThrowVelocity = TargetData.Velocity;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if (ActiveDuration >= Settings.ThrowEndDelay)
			return true;

        if(!PlayerComp.AimComp.IsAiming(PlayerComp))
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FWindJavelinThrowOnActivatedParams Params)
    {
        Player.BlockCapabilities(IceBow::IceBowTag, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);

        PlayerComp.bIsThrowing = true;
        PlayerComp.bThrow = false;

        if(IsValid(PlayerComp.ThrownWindJavelin))
        {
            // if(TimeLoop::CanPlayerInteract())
            //     StartTimeLoopTimerTask(PlayerComp.ThrownWindJavelin, UWindJavelinDelayedDestroyTask::StaticClass(), 2.0);

            PlayerComp.ThrownWindJavelin = nullptr;
        }

        PlayerComp.WindJavelin.DetachFromActor(EDetachmentRule::KeepWorld);
        
        PlayerComp.WindJavelin.Settings = Settings;

        FWindJavelinThrowEventData ThrowData;
        ThrowData.ThrowImpulse = Params.ThrowVelocity;
        
		UWindJavelinEventHandler::Trigger_Throw(Player, ThrowData);
        UWindJavelinProjectileEventHandler::Trigger_Throw(PlayerComp.WindJavelin, ThrowData);

        PlayerComp.WindJavelin.Throw(Params.ThrowVelocity, PlayerComp.Settings.Gravity, ProjectileProximityComp);

        // Camera impulse
        Player.ApplyCameraImpulse(Settings.CameraImpulse, this);

        // Camera shake
        if(Settings.ThrowCameraShake != nullptr)
            Player.PlayCameraShake(Settings.ThrowCameraShake, this);

        // Force Feedback
        if(Settings.ThrowForceFeedback != nullptr)
            Player.PlayForceFeedback(Settings.ThrowForceFeedback, false, false, this, 1.0);

        PlayerComp.SetChargeFactor(0.0, true);
        PlayerComp.ThrownWindJavelin = PlayerComp.WindJavelin;
        PlayerComp.WindJavelin = nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		Player.UnblockCapabilities(IceBow::IceBowTag, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
        PlayerComp.bIsThrowing = false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(Player.Mesh.CanRequestOverrideFeature())
            Player.Mesh.RequestOverrideFeature(WindJavelin::Feature, this);

        if (MoveComp.PrepareMove(Movement))
        {
            if(HasControl())
            {
                FAimingResult AimResult = PlayerComp.AimComp.GetAimingTarget(PlayerComp);
                float CapabilityCompletion = Math::Saturate(ActiveDuration / Settings.ThrowEndDelay);
                float Multiplier = Settings.RecoilCurve.GetFloatValue(CapabilityCompletion);

                float RecoilIntensity = MoveComp.IsOnAnyGround() ? Settings.RecoilGroundIntensity : Settings.RecoilAirIntensity;
                FVector HorizontalVelocity = -AimResult.AimDirection * RecoilIntensity * Multiplier;
                HorizontalVelocity = HorizontalVelocity.VectorPlaneProject(MoveComp.WorldUp);

                FVector VerticalVelocity = MoveComp.Gravity * 2.0 * CapabilityCompletion;

                Movement.AddVelocity((HorizontalVelocity + VerticalVelocity) * DeltaTime);

                Movement.InterpRotationTo(AimResult.AimDirection.ToOrientationQuat(), 10);
            }
            else
            {
                Movement.ApplyCrumbSyncedAirMovement();
            }

            MoveComp.ApplyMoveAndRequestOverrideFeature(Movement, WindJavelin::Feature);
        }
    }
    
    UWindJavelinSettings GetSettings() const property
    {
        return PlayerComp.Settings;
    }
}