UCLASS(Abstract)
class UIslandZombieWallDamageEffectHandler : UHazeEffectEventHandler
{
    // The owner hit a wall (WallDamage.WallImpact)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void WallImpact() {}
}