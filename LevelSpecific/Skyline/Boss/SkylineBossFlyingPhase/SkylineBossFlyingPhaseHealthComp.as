class USkylineBossFlyingPhaseHealthComp : UBasicAIHealthComponent
{
	default MaxHealth = 10.0;

	UFUNCTION()
	private void HandleProjectileImpact(FGravityBikeWeaponImpactData ImpactData)
	{		
		float ScaledDamage = ImpactData.Damage * 0.01;
		float DamageTaken = Math::Min(CurrentHealth, ScaledDamage);

		TakeDamage(ImpactData.Damage, EDamageType::Default, ImpactData.Instigator);


		if (CurrentHealth <= 0.0)
		{
			Print("Death");
		}
	}
};