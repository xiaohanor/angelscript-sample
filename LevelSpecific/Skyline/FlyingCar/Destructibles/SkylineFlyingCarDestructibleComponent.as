event void FSkylineFlyingCarDestructibleHitEvent(FSkylineFlyingCarGunHit HitInfo);
event void FSkylineFlyingCarDestructibleDestroyedEvent(FSkylineFlyingCarGunHit LastHitInfo);

UCLASS(NotBlueprintable)
class USkylineFlyingCarDestructibleComponent : UActorComponent
{
	UPROPERTY()
	private const float MaxHealth = 0.6;

	// How many secs must pass after taking damage before being able to take damage again
	UPROPERTY()
	private const float TakeDamageCooldown = 0.1;

	UPROPERTY()
	FSkylineFlyingCarDestructibleHitEvent OnHit;

	UPROPERTY()
	FSkylineFlyingCarDestructibleDestroyedEvent OnDestroyed;

	private float CurrentHealth;

	private float LastTakeDamageTime = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentHealth = MaxHealth;
	}

	void TakeDamage(FSkylineFlyingCarGunHit HitInfo)
	{
		if (JustTookDamage())
			return;

		if (HitInfo.bControlSide)
		{
			CurrentHealth -= HitInfo.Damage;
			LastTakeDamageTime = Time::GameTimeSeconds;

			// Fire event
			if (CurrentHealth <= 0.0)
			{
				OnDestroyed.Broadcast(HitInfo);
			}
			else
			{
				OnHit.Broadcast(HitInfo);
			}
		}
	}

	bool JustTookDamage() const
	{
		if(LastTakeDamageTime < 0)
			return false;

		return Time::GetGameTimeSince(LastTakeDamageTime) < TakeDamageCooldown;
	}
}