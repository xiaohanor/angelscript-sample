event void FOnDragonSwordBreakableDeath();

class UStoneBreakableHealthComponent : UActorComponent
{
	UPROPERTY()
	FOnDragonSwordBreakableDeath OnDragonSwordBreakableDeath;

	UPROPERTY(EditAnywhere)
	float MaxHealth = 1.0;

	private float Health;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Health = MaxHealth;
	}

	UFUNCTION()
	void TakeDamage(float Damage)
	{	
		Health -= Damage;

		if (Health <= 0.0)
		{
			Death();
		}
	}

	UFUNCTION()
	float GetHealth()
	{
		return Health;
	}

	UFUNCTION()
	void Death()
	{
		OnDragonSwordBreakableDeath.Broadcast();
	}
}