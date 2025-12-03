struct FTundraPondBeastBaitOnImpactParameters
{
	UPROPERTY()
	ATundraPondBeastBait BeastBaitProjectile;

	UPROPERTY()
	FVector ProjectileLocation;
}

UCLASS(Abstract)
class UTundraPondBeastBaitEffectHandler : UHazeEffectEventHandler
{
	//default DefaultEventNamespace = n"TundraBeastBait";

	// Called when the projectile impacts into something and gives the location of the projectile when doing so (TundraBeastBait.OnImpact)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact(FTundraPondBeastBaitOnImpactParameters ImpactParameters) {}
}