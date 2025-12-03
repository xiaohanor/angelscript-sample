class UIceLakeWindWalkForceCapability : UHazePlayerCapability
{
    default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;

    UWindWalkComponent PlayerComp;
    UWindWalkDataComponent DataComp;
    UWindDirectionResponseComponent ResponseComp;
    UPlayerMovementComponent MoveComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UWindWalkComponent::GetOrCreate(Player);
        DataComp = UWindWalkDataComponent::Get(Player);
        MoveComp = UPlayerMovementComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if (MoveComp.HasMovedThisFrame())
			return false;

        if(!PlayerComp.GetIsStrongWind())
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if (MoveComp.HasMovedThisFrame())
			return true;

        if(!PlayerComp.GetIsStrongWind())
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        if(ResponseComp == nullptr)
            ResponseComp = UWindDirectionResponseComponent::GetOrCreate(Player);

        Player.BlockCapabilities(PlayerMovementTags::Dash, this);
        Player.BlockCapabilities(PlayerMovementTags::Sprint, this);
        Player.BlockCapabilities(PlayerMovementTags::Jump, this);
        Player.BlockCapabilities(PlayerMovementTags::AirJump, this);

        MoveComp.ApplyMoveSpeedMultiplier(DataComp.Settings.MaxSpeedMultiplier, this);
        UPlayerFloorMotionSettings::SetDeceleration(Player, DataComp.Settings.SlowDownInterpSpeed, this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
        Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);
        Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
        Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);

        MoveComp.ClearMoveSpeedMultiplier(this);
        UPlayerFloorMotionSettings::ClearDeceleration(Player, this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FVector WindForce = ResponseComp.WindDirection;
        Player.AddMovementImpulse(WindForce * DataComp.Settings.ImpulseMultiplier, WindWalk::WindWalkImpulseTag);
    }
}