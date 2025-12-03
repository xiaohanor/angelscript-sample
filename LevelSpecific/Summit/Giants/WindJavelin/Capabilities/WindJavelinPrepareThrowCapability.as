struct FWindJavelinPrepareThrowOnDeactivatedParams
{
    bool bFinished;
}

/**
 * 
 */
class UWindJavelinPrepareThrowCapability : UHazePlayerCapability
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

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UWindJavelinPlayerComponent::Get(Player);
        MoveComp = UPlayerMovementComponent::Get(Player);
        Movement = MoveComp.SetupSweepingMovementData();
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(IsActioning(WindJavelin::ThrowAction))
            return false;

        if(!PlayerComp.bIsAiming)
            return false;

        if(PlayerComp.WindJavelin == nullptr)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate(FWindJavelinPrepareThrowOnDeactivatedParams& Params) const
    {
		if (ActiveDuration >= GetStartDelay())
        {
            Params.bFinished = true;
			return true;
        }

        if(!PlayerComp.AimComp.IsAiming(PlayerComp))
            return true;

        return false;
    }

    bool GetAimingWasInterrupted() const
    {
        if(PlayerComp.AimDuration > KINDA_SMALL_NUMBER && PlayerComp.AimDuration < PlayerComp.Settings.ChargeTime)
        {
            if(!IsActioning(WindJavelin::ThrowAction))
                return true;
        }

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		Player.BlockCapabilities(IceBow::IceBowTag, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
        PlayerComp.bIsThrowing = true;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FWindJavelinPrepareThrowOnDeactivatedParams Params)
    {
        if(!Params.bFinished && PlayerComp.WindJavelin != nullptr)
        {
            PlayerComp.WindJavelin.DestroyActor();
            PlayerComp.WindJavelin = nullptr;

            PlayerComp.bIsThrowing = false;
        }
        else
        {
            PlayerComp.bThrow = true;
        }

        Player.UnblockCapabilities(IceBow::IceBowTag, this);
        Player.UnblockCapabilities(CapabilityTags::Movement, this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if(Player.Mesh.CanRequestOverrideFeature())
            Player.Mesh.RequestOverrideFeature(WindJavelin::Feature, this);

        // We want to activate even when waiting for the Aim animation to begin, but we don't want to start
        // charging before the animation is finished.
        // Updated aim result since player can still move aim while waiting to throw
        FAimingResult AimResult = PlayerComp.AimComp.GetAimingTarget(PlayerComp);
        Player.SetMovementFacingDirection(AimResult.AimDirection.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal());

        // Turn towards shotting direction
        if (MoveComp.PrepareMove(Movement))
        {
            if(HasControl())
            {
                // Add drag
                FVector Velocity = MoveComp.Velocity;
                Velocity -= Velocity * DeltaTime * 4.0;
                Movement.AddVelocity(Velocity);

                // Add a bit of delay before starting rotation (wait for lady to jump)
                if (ActiveDuration > 0.1)
                {
                    // Rotate towards throw direction
                    float AngularDistance = (AimResult.AimDirection.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal().AngularDistanceForNormals(Player.ActorForwardVector));
                    float RotationSpeed = AngularDistance / Settings.ThrowStartDelay;
                    Movement.InterpRotationToTargetFacingRotation(RotationSpeed / Math::Max(DeltaTime, ActiveDuration));
                }
            }
            else
            {
                Movement.ApplyCrumbSyncedAirMovement();
            }

            MoveComp.ApplyMoveAndRequestOverrideFeature(Movement, WindJavelin::Feature);
        }

        PlayerComp.SetChargeFactor(ActiveDuration / Settings.ThrowStartDelay, true);
    }

    float GetStartDelay() const
    {
        return GetAimingWasInterrupted() ? Settings.ThrowStartDelay + Settings.WindAimToWindThrowTime : Settings.ThrowStartDelay;
    }
    
    UWindJavelinSettings GetSettings() const property
    {
        return PlayerComp.Settings;
    }
}