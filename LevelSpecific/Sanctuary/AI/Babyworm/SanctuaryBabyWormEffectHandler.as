UCLASS(Abstract)
class USanctuaryBabyWormEffectHandler : UHazeEffectEventHandler
{
    // Baby worm is torn apart by centipede
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTornApart() {}
}