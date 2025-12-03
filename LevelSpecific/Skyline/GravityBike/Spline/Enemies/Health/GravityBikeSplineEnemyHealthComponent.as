event void FGravityBikeSplineEnemyOnTakeDamage(FGravityBikeSplineEnemyTakeDamageData DamageData);
event void FGravityBikeSplineEnemyOnDeath(FGravityBikeSplineEnemyDeathData DeathData);
event void FGravityBikeSplineEnemyOnRespawn(FGravityBikeSplineEnemyRespawnData RespawnData);

enum EGravityBikeSplineEnemyDamageType
{
	Missile,
	Throwable,
};

struct FGravityBikeSplineEnemyTakeDamageData
{
	UPROPERTY()
	EGravityBikeSplineEnemyDamageType DamageType;

	UPROPERTY()
	float Damage;

	UPROPERTY()
	bool bDamageIsFraction = true;

	UPROPERTY()
	FVector DamageDirection;

	FGravityBikeSplineEnemyTakeDamageData(
		EGravityBikeSplineEnemyDamageType InDamageType,
		float InDamage,
		bool bInDamageIsFraction,
		FVector InDamageDirection)
	{
		DamageType = InDamageType;
		Damage = InDamage;
		bDamageIsFraction = bInDamageIsFraction;
		DamageDirection = InDamageDirection;
	}

	float GetDamage(float MaxHealth) const
	{
		if(bDamageIsFraction)
			return MaxHealth * Damage;
		else
			return Damage;
	}

	bool ShouldApplyImpulse() const
	{
		if(DamageDirection.IsNearlyZero())
			return false;
		
		switch(DamageType)
		{
			case EGravityBikeSplineEnemyDamageType::Missile:
				return true;

			case EGravityBikeSplineEnemyDamageType::Throwable:
				return true;
		}
	}
};

struct FGravityBikeSplineEnemyDeathData
{
	UPROPERTY()
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UPROPERTY()
	EGravityBikeSplineEnemyDamageType DamageType;

	FGravityBikeSplineEnemyDeathData(UGravityBikeSplineEnemyHealthComponent InHealthComp, EGravityBikeSplineEnemyDamageType InDamageType)
	{
		HealthComp = InHealthComp;
		DamageType = InDamageType;
	}
};

struct FGravityBikeSplineEnemyRespawnData
{
	UPROPERTY()
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	FGravityBikeSplineEnemyRespawnData(UGravityBikeSplineEnemyHealthComponent InHealthComp)
	{
		HealthComp = InHealthComp;
	}
}

UCLASS(NotBlueprintable, HideCategories = "Activation Cooking Tags AssetUserData Navigation ComponentTick Disable")
class UGravityBikeSplineEnemyHealthComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Health")
	private float MaxHealth = 1;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Health")
	private bool bCanRespawn = true;

	UPROPERTY()
	FGravityBikeSplineEnemyOnTakeDamage PreTakeDamage;

	UPROPERTY()
	FGravityBikeSplineEnemyOnTakeDamage PostTakeDamage;

	UPROPERTY()
	FGravityBikeSplineEnemyOnDeath OnDeath;

	UPROPERTY()
	FGravityBikeSplineEnemyOnRespawn OnRespawn;

	private float CurrentHealth;
	bool bExplode = false;
	bool bIsRespawning = false;
	TSet<FInstigator> BlockRespawnInstigators;
	UGravityBikeSplineEnemyMovementComponent SplineMoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentHealth = MaxHealth;
		SplineMoveComp = UGravityBikeSplineEnemyMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Max Health", MaxHealth)
			.Value("Current Health", CurrentHealth)
			.Value("Explode", bExplode)
			.Value("Is Respawning", bIsRespawning)
			.Value("Is Alive", IsAlive())
			.Value("Health Fraction", GetHealthFraction())
		;
#endif
	}

	void TakeDamage(FGravityBikeSplineEnemyTakeDamageData DamageData)
	{
		if(bIsRespawning)
			return;
		
		bool bWasAlive = IsAlive();

		PreTakeDamage.Broadcast(DamageData);

		const float Damage = DamageData.GetDamage(MaxHealth);
		CurrentHealth -= Damage;

		PostTakeDamage.Broadcast(DamageData);

		if(bWasAlive && IsDead())
		{
			FGravityBikeSplineEnemyDeathData DeathData(this, DamageData.DamageType);
			OnDeath.Broadcast(DeathData);
		}
	}

	bool CanRespawn() const
	{
		check(HasControl());

		if(!bCanRespawn)
			return false;

		if(!BlockRespawnInstigators.IsEmpty())
			return false;

		if(SplineMoveComp.HasPassedSplineEnd())
			return false;

		return true;
	}

	void Respawn()
	{
		if(HasControl())
		{
			if(!ensure(CanRespawn()))
				return;
		}
		
		Reset();
		FGravityBikeSplineEnemyRespawnData RespawnData = FGravityBikeSplineEnemyRespawnData(this);
		OnRespawn.Broadcast(RespawnData);
	}

	UFUNCTION(BlueprintPure)
	bool IsAlive() const
	{
		if(bIsRespawning)
			return false;

		return (CurrentHealth > 0.0);
	}

	bool IsDead() const
	{
		return !IsAlive();
	}

	float GetMaxHealth() const
	{
		return MaxHealth;
	}

	float GetCurrentHealth() const
	{
		return CurrentHealth;
	}

	float GetHealthFraction() const
	{
		if (MaxHealth < KINDA_SMALL_NUMBER)
			return 1.0;

		if(CurrentHealth < 0)
			return 0;

		return CurrentHealth / MaxHealth;
	}

	bool IsRespawning() const
	{
		return bIsRespawning;
	}

	void Reset()
	{
		CurrentHealth = MaxHealth;
		bIsRespawning = false;
		bExplode = false;
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void DevKill()
	{
		FGravityBikeSplineEnemyTakeDamageData Damage;
		Damage.Damage = 1;
		Damage.DamageType = EGravityBikeSplineEnemyDamageType::Throwable;
		Damage.bDamageIsFraction = true;
		TakeDamage(Damage);
	}
#endif
};