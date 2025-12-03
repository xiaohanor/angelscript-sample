// Give this to any actor which wants to deal damage to the player and needs to keep track of different damage types 
class UDealPlayerDamageComponent : UActorComponent
{
	UPROPERTY()
	TMap<EDamageEffectType, TSubclassOf<UDamageEffect>> DamageEffects;

	UPROPERTY()
	TMap<EDeathEffectType, TSubclassOf<UDeathEffect>> DeathEffects;

	void DealDamage(AActor Target, float Damage, EDamageEffectType DamageType = EDamageEffectType::Generic, EDeathEffectType DeathType = EDeathEffectType::Generic, bool bApplyInvulnerability = true, FPlayerDeathDamageParams DeathParams = FPlayerDeathDamageParams())
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Target);
		if (HealthComp == nullptr)
			return;

		TSubclassOf<UDamageEffect> DamageEffect = nullptr;
		DamageEffects.Find(DamageType, DamageEffect);	
		TSubclassOf<UDeathEffect> DeathEffect = nullptr;
		DeathEffects.Find(DeathType, DeathEffect);	
		HealthComp.DamagePlayer(Damage, DamageEffect, DeathEffect, bApplyInvulnerability, DeathParams);
	}

	void DealBatchedDamageOverTime(AActor Target, float Damage, EDamageEffectType DamageType = EDamageEffectType::Generic, EDeathEffectType DeathType = EDeathEffectType::Generic)
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Target);
		if (HealthComp == nullptr)
			return;

		TSubclassOf<UDamageEffect> DamageEffect = nullptr;
		DamageEffects.Find(DamageType, DamageEffect);	
		TSubclassOf<UDeathEffect> DeathEffect = nullptr;
		DeathEffects.Find(DeathType, DeathEffect);	
		HealthComp.DealBatchedDamage(Damage, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);
	}
}

mixin void DealTypedDamage(AHazePlayerCharacter Target, AActor DamageDealer, float Damage, EDamageEffectType DamageType = EDamageEffectType::Generic, EDeathEffectType DeathType = EDeathEffectType::Generic, bool bApplyInvulnerability = true, FPlayerDeathDamageParams DeathParams = FPlayerDeathDamageParams())
{
	if (Target == nullptr)
		return;
	if (DamageDealer == nullptr)
		return;
	UDealPlayerDamageComponent DamageComp = UDealPlayerDamageComponent::Get(DamageDealer);
	if (DamageComp == nullptr)
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Target);
		if (HealthComp == nullptr)
			return;
		HealthComp.DamagePlayer(Damage, nullptr, nullptr, bApplyInvulnerability, DeathParams);		
		return;
	}

	DamageComp.DealDamage(Target, Damage, DamageType, DeathType, bApplyInvulnerability, DeathParams);
} 

mixin void DealTypedDamageBatchedOverTime(AHazePlayerCharacter Target, AActor DamageDealer, float Damage, EDamageEffectType DamageType = EDamageEffectType::Generic, EDeathEffectType DeathType = EDeathEffectType::Generic)
{
	if (Target == nullptr)
		return;
	if (DamageDealer == nullptr)
		return;
	UDealPlayerDamageComponent DamageComp = UDealPlayerDamageComponent::Get(DamageDealer);
	if (DamageComp == nullptr)
	{
		Target.DealBatchedDamageOverTime(Damage, FPlayerDeathDamageParams());
		return;
	}

	DamageComp.DealBatchedDamageOverTime(Target, Damage, DamageType, DeathType);
} 
