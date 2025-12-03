UCLASS(Abstract)
class UCoastBomblingEffectHandler : UHazeEffectEventHandler
{

    // The owner took damage (CoastBombling.OnTakeDamage)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTakeDamage() {}

	// The owner died (CoastBombling.OnDeath)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath(FCoastBomblingEffectOnDeathData Data) {}

	// The owner unspawned (CoastBombling.OnUnspawn)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnUnspawn() {}

	// The owner respawned (CoastBombling.OnRespawn)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRespawn() {}

	// The exploder exploded on proximity (CoastBombling.OnProximityExplosion)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnProximityExplosion(FCoastBomblingOnProximityExplosionData Data) {}
}

struct FCoastBomblingEffectOnDeathData
{
	UPROPERTY(BlueprintReadOnly)
	float DeathDuration;

	UPROPERTY(BlueprintReadOnly)
	AActor ParentActor;

	FCoastBomblingEffectOnDeathData(AActor _ParentActor)
	{
		ParentActor = _ParentActor;
	}
}

struct FCoastBomblingOnProximityExplosionData
{
	UPROPERTY(BlueprintReadOnly)
	AActor ParentActor;

	FCoastBomblingOnProximityExplosionData(AActor _ParentActor)
	{
		ParentActor = _ParentActor;
	}
}