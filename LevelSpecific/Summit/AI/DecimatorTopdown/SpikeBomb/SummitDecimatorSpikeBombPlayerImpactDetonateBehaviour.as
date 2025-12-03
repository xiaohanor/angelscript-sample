
// Can only damage player
class USummitDecimatorSpikeBombPlayerImpactDetonateBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitDecimatorSpikeBombSettings Settings;
	
	UBasicAIHealthComponent HealthComp;
	USummitMeltComponent MeltComp;

	AAISummitDecimatorSpikeBomb SpikeBomb;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitDecimatorSpikeBombSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MeltComp = USummitMeltComponent::Get(Owner);
		SpikeBomb = Cast<AAISummitDecimatorSpikeBomb>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (MeltComp.bMelted)
			return false;

		if ((!TargetComp.IsValidTarget(Game::Mio) || !Owner.ActorCenterLocation.IsWithinDist(Game::Mio.ActorCenterLocation, Settings.PlayerImpactDetonationActivationRange))
			&&
		    (!TargetComp.IsValidTarget(Game::Zoe) ||  !Owner.ActorCenterLocation.IsWithinDist(Game::Zoe.ActorCenterLocation, Settings.PlayerImpactDetonationActivationRange)))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if (Super::ShouldDeactivate())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		// Spawn Explosion Trail and kill self
		SpikeBomb.OnSpikeBombExploded.Broadcast(Owner.ActorLocation);
		//HealthComp.TakeDamage(1.0, EDamageType::Explosion, Owner);
		
		// Deal damage		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Owner.ActorCenterLocation.IsWithinDist(Player.ActorCenterLocation, Settings.DetonationExplosionDamageRange))
				continue;

			Player.DealTypedDamage(Owner, Settings.DetonationExplosionPlayerDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
		}

		// Trigger effect
		USummitDecimatorSpikeBombEffectsHandler::Trigger_OnExplode(Owner);

#if EDITOR
		UHazeTeam DecimatorTeam = HazeTeam::GetTeam((DecimatorTopdownTags::DecimatorTeamTag));
		for (auto Member : DecimatorTeam.GetMembers())
		{
			if (Member == nullptr)
				continue;
			//Member.bHazeEditorOnlyDebugBool = true;
			if (Member.bHazeEditorOnlyDebugBool)
			{
				Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.DetonationExplosionDamageRange, LineColor = FLinearColor::Red, Duration = 1.0);
			}
		}		
#endif
	}

}