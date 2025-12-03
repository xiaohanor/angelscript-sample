namespace Damage
{
	/**
	* Deal damage to any player within given radius.
	* @param `Epicenter` 				Center of damage sphere
	* @param `Radius` 					How far from epicenter damage will be dealt
	* @param `Damage` 					Amount of damage (within InnerDamageRadius)
	* @param `InnerDamageRadius` 		Beyond this range damage falls off, if less than Radius.
	* @param `DamageFalloffExponent`	How fast damage falls off between MaxDamageRadius and Radius. E.g. 1 is linear falloff.
	* @param `DamageEffect`				What damage effect class will be used when dealing non-lethal damage
	* @param `DeathEffect`				What death effect class will be used when dealing lethal damage
	*/
	void PlayerRadialDamage(FVector Epicenter, float Radius, float Damage, float InnerDamageRadius = BIG_NUMBER, 
							float DamageFalloffExponent = 1.0, FPlayerDeathDamageParams DeathParams = FPlayerDeathDamageParams(), TSubclassOf<UDamageEffect> DamageEffect = nullptr, 
							TSubclassOf<UDeathEffect> DeathEffect = nullptr) 
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			float RadialDamage = Damage * GetRadialDamageFactor(Player.ActorCenterLocation, Epicenter, Radius, InnerDamageRadius, DamageFalloffExponent);
			if (RadialDamage > SMALL_NUMBER)
				Player.DamagePlayerHealth(RadialDamage, DeathParams, DamageEffect, DeathEffect);
		}
	}

	/**
	* Deal damage to any AI targets within given radius.
	* @param `Epicenter` 				Center of damage sphere
	* @param `Radius` 					How far from epicenter damage will be dealt
	* @param `Damage` 					Amount of damage (within InnerDamageRadius)
	* @param `Instigator`				The one responsible for dealing damage			
	* @param `Targets`					List of potential targets
	* @param `InnerDamageRadius` 		Beyond this range damage falls off, if less than Radius.
	* @param `DamageFalloffExponent`	How fast damage falls off between MaxDamageRadius and Radius. E.g. 1 is linear falloff.
	*/
	void AIRadialDamageToTeam(FVector Epicenter, float Radius, float Damage, AHazeActor Instigator, FName TeamName,
					  		  EDamageType DamageType = EDamageType::Default, float InnerDamageRadius = BIG_NUMBER, float DamageFalloffExponent = 1.0) 
	{
		UHazeTeam Team = HazeTeam::GetTeam(TeamName);
		if (Team == nullptr)
			return;

		for (AHazeActor Target : Team.GetMembers())
		{
			if (Target == nullptr)
				continue;

			float RadialDamage = Damage * GetRadialDamageFactor(Target.ActorCenterLocation, Epicenter, Radius, InnerDamageRadius, DamageFalloffExponent);
			if (RadialDamage > SMALL_NUMBER)
				AITakeDamage(Target, RadialDamage, Instigator, DamageType);
		}
	}

	float GetRadialDamageFactor(FVector TargetLocation, FVector Epicenter, float Radius, float InnerRadius = BIG_NUMBER, float DamageFalloffExponent = 1.0)
	{
		// Are we within damage radius?
		if (!Epicenter.IsWithinDist(TargetLocation, Radius))
			return 0.0;

		if ((Radius > InnerRadius) && !Epicenter.IsWithinDist(TargetLocation, InnerRadius))
		{
			// In damage falloff zone, reduce damage
			float OutsideFraction = (Epicenter.Distance(TargetLocation) - InnerRadius) / (Radius - InnerRadius);
			return Math::Pow(1.0 - OutsideFraction, DamageFalloffExponent);
		}

		// Within inner radius, deal full damage
		return 1.0; 
	}

	void AITakeDamage(AActor Actor, float Damage, AHazeActor Instigator, EDamageType DamageType = EDamageType::Default)
	{
		if (Actor == nullptr)
			return;

		UBasicAIHealthComponent AIHealthComp = UBasicAIHealthComponent::Get(Actor);
		if (AIHealthComp != nullptr)
			AIHealthComp.TakeDamage(Damage, DamageType, Instigator);
	}
}
