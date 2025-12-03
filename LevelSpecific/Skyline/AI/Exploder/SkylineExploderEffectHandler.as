UCLASS(Abstract)
class USkylineExploderEffectHandler : UHazeEffectEventHandler
{

    // The owner took damage (SkylineExploder.OnTakeDamage)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTakeDamage() {}

	// The owner died (SkylineExploder.OnDeath)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath(FSkylineExploderEffectOnDeathData Data) {}

	// The owner unspawned (SkylineExploder.OnUnspawn)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnUnspawn() {}

	// The owner respawned (SkylineExploder.OnRespawn)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRespawn() {}

	// The exploder exploded on proximity (SkylineExploder.OnProximityExplosion)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnProximityExplosion() {}
}

struct FSkylineExploderEffectOnDeathData
{
	UPROPERTY(BlueprintReadOnly)
	float DeathDuration;
}