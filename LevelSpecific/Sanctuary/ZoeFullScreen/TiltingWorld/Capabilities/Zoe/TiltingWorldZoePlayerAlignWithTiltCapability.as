class UTiltingWorldZoePlayerAlignWithTiltCapability : UHazePlayerCapability
{
    UTiltingWorldZoeComponent PlayerComp;
    UTiltingWorldMioComponent MioComp;
    UHazeMovementComponent MoveComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UTiltingWorldZoeComponent::GetOrCreate(Player);
        MioComp = UTiltingWorldMioComponent::Get(Game::GetMio());
        MoveComp = UHazeMovementComponent::Get(Player);
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
        if(MioComp.Settings.bClampTilt)
            UMovementStandardSettings::SetWalkableSlopeAngle(Player, MioComp.Settings.ClampAngle + MioComp.Settings.WalkableSlopeAngleMargin, this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        if(MioComp.Settings.bClampTilt)
            UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.OverrideGravityDirection(-MioComp.SmoothWorldRotation.UpVector, this);
	}
}