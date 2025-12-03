class USplineCorridorBendZoeCapability : UHazePlayerCapability
{
    USplineCorridorBendZoeComponent PlayerComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = USplineCorridorBendZoeComponent::Get(Player);
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
}