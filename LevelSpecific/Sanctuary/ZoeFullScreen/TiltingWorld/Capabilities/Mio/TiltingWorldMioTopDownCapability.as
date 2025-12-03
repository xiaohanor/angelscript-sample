class UTiltingWorldMioTopDownCapability : UHazePlayerCapability
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
		if(!WasActionStarted(ActionNames::Grapple))
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(WasActionStarted(ActionNames::Grapple))
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		ZoeComp.SetWorldUp(FVector(-1.0, 0.0, 0.0));
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
		ZoeComp.ResetWorldUp();
    }
}