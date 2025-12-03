

class UIslandZoomotronSidescrollerAttackBehaviour : UBasicBehaviour
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
		
		if ((!Owner.ActorCenterLocation.IsWithinDist(Game::Players[0].ActorCenterLocation, Settings.SidescrollerExplodeRange) || Game::Players[0].IsPlayerDeadOrRespawning())
		    &&
			(!Owner.ActorCenterLocation.IsWithinDist(Game::Players[1].ActorCenterLocation, Settings.SidescrollerExplodeRange) || Game::Players[1].IsPlayerDeadOrRespawning()))
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
			if (!Owner.ActorCenterLocation.IsWithinDist(Player.ActorCenterLocation, Settings.SidescrollerExplosionDamageRange))
				continue;

			if (Player.HasControl())
			{			
				Player.DealTypedDamage(Owner, Settings.SidescrollerExplosionDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
			}
		}		
		
		// Trigger effect
		UIslandZoomotronEffectHandler::Trigger_OnChargeHit(Owner, FZoomotronChargeHitParams(TargetComp.Target));

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.SidescrollerExplosionDamageRange, LineColor = FLinearColor::Red, Duration = 1.0);
		}
#endif
	}

}