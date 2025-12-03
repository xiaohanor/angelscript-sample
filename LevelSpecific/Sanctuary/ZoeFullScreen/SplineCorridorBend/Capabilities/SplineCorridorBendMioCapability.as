class USplineCorridorBendMioCapability : UHazePlayerCapability
{
    USplineCorridorBendMioComponent PlayerComp;
    USplineCorridorBendMioDataComponent DataComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = USplineCorridorBendMioComponent::GetOrCreate(Player);
        DataComp = USplineCorridorBendMioDataComponent::Get(Player);
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
        const FVector2D InputVector = MioFullScreen::GetStickInput(this);

        PlayerComp.OnSplineCorridorInput.Broadcast(-InputVector.Y * DataComp.Settings.BendSpeed * DeltaTime);
    }
}