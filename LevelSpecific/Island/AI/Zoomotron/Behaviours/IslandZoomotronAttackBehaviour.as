

class UIslandZoomotronAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;
	UIslandZoomotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = UIslandZoomotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		
		if (!TargetComp.HasValidTarget())
			return false;

		if (!Owner.ActorCenterLocation.IsWithinDist(Game::Players[0].ActorCenterLocation, Settings.ExplodeRange) &&
		    !Owner.ActorCenterLocation.IsWithinDist(Game::Players[1].ActorCenterLocation, Settings.ExplodeRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if (!Super::ShouldDeactivate())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		// Kill self
		HealthComp.TakeDamage(1.0, EDamageType::Explosion, Owner);

		// Deal damage		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Owner.ActorCenterLocation.IsWithinDist(Player.ActorCenterLocation, Settings.ExplosionDamageRange))
				continue;
			
			Player.DealTypedDamage(Owner, Settings.ExplosionDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
		}		
		
		// Trigger effect
		UIslandZoomotronEffectHandler::Trigger_OnChargeHit(Owner, FZoomotronChargeHitParams(TargetComp.Target));

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.ExplosionDamageRange, LineColor = FLinearColor::Red, Duration = 1.0);
		}
#endif
	}

}