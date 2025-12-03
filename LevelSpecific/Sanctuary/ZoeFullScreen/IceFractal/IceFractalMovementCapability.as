class UIceFractalMovementCapability : UHazePlayerCapability
{
    UIceFractalDataComponent DataComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        DataComp = UIceFractalDataComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        if(DataComp.Settings.bBlockJump)
	        Player.BlockCapabilities(PlayerMovementTags::Jump, this);

        if(DataComp.Settings.bBlockAirJump)
	        Player.BlockCapabilities(PlayerMovementTags::AirJump, this);

        if(DataComp.Settings.bBlockDash)
	        Player.BlockCapabilities(PlayerMovementTags::Dash, this);

        if(DataComp.Settings.bBlockSprint)
	        Player.BlockCapabilities(PlayerMovementTags::Sprint, this);

        //UMovementSteppingSettings::SetStepDownSize(Player, FMovementSettingsValue::MakeValue(1), this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        if(DataComp.Settings.bBlockJump)
	        Player.UnblockCapabilities(PlayerMovementTags::Jump, this);

        if(DataComp.Settings.bBlockAirJump)
	        Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);

        if(DataComp.Settings.bBlockDash)
            Player.UnblockCapabilities(PlayerMovementTags::Dash, this);

        if(DataComp.Settings.bBlockSprint)
	        Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);

        //UMovementSteppingSettings::ClearStepDownSize(Player, this);
    }
}