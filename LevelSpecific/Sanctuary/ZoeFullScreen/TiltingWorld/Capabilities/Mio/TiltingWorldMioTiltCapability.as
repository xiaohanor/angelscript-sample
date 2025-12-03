class UTiltingWorldMioTiltCapability : UHazePlayerCapability
{
    UTiltingWorldMioComponent PlayerComp;
	UTiltingWorldZoeComponent ZoeComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = UTiltingWorldMioComponent::Get(Player);
		ZoeComp = UTiltingWorldZoeComponent::GetOrCreate(Game::GetZoe());
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
    void TickActive(float DeltaTime)
    {
		if(ZoeComp.bOverrideWorldUp)
		{
			FRotator WorldRotation = FRotator::MakeFromZX(ZoeComp.WorldUp, FVector::UpVector);
			PlayerComp.SetWorldRotation(WorldRotation);
			PlayerComp.UpdateSmoothWorldRotation(DeltaTime);
			return;
		}
		else if(ZoeComp.bResetWorldUp)
		{
			PlayerComp.SetWorldRotation(FRotator::ZeroRotator);
			ZoeComp.bResetWorldUp = false;
		}

        FRotator WorldRotation = PlayerComp.WorldRotation_Internal;

        const FVector2D InputVector = MioFullScreen::GetStickInput(this);

        WorldRotation.Roll += (InputVector.X * PlayerComp.Settings.TiltSpeed * PlayerComp.Settings.RollMultiplier * DeltaTime);

        if(PlayerComp.Settings.bAllowPitching)
            WorldRotation.Pitch -= (InputVector.Y * PlayerComp.Settings.TiltSpeed * PlayerComp.Settings.PitchMultiplier * DeltaTime);

        if(PlayerComp.Settings.bClampTilt)
        {
            WorldRotation.Roll  = Math::Clamp(WorldRotation.Roll, -PlayerComp.Settings.ClampAngle, PlayerComp.Settings.ClampAngle);

            if(PlayerComp.Settings.bAllowPitching)
                WorldRotation.Pitch  = Math::Clamp(WorldRotation.Pitch, -PlayerComp.Settings.ClampAngle, PlayerComp.Settings.ClampAngle);
        }

        PlayerComp.SetWorldRotation(WorldRotation);
        PlayerComp.UpdateSmoothWorldRotation(DeltaTime);
    }
}