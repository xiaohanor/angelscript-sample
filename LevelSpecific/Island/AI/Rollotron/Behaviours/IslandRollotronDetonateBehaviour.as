class UIslandRollotronDetonateBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	private float TelegraphEndTime;
	AHazePlayerCharacter PlayerTarget;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	UIslandRollotronSpikeComponent SpikeComp;
	UPoseableMeshComponent MeshComp;
	UIslandRollotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		SpikeComp = UIslandRollotronSpikeComponent::Get(Owner);
		MeshComp = UPoseableMeshComponent::Get(Owner);
		Settings = UIslandRollotronSettings::GetSettings(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if ((!TargetComp.IsValidTarget(Game::Mio) || !Owner.ActorCenterLocation.IsWithinDist(Game::Mio.ActorCenterLocation, Settings.DetonationRange))
			&&
		    (!TargetComp.IsValidTarget(Game::Zoe) || !Owner.ActorCenterLocation.IsWithinDist(Game::Zoe.ActorCenterLocation, Settings.DetonationRange)))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (TelegraphEndTime < Time::GameTimeSeconds)
			return true;

		if ((Owner.ActorCenterLocation.IsWithinDist(Game::Mio.ActorCenterLocation, Settings.InstantDetonationRange) && TargetComp.IsValidTarget(Game::Mio))
			||
		    (Owner.ActorCenterLocation.IsWithinDist(Game::Zoe.ActorCenterLocation, Settings.InstantDetonationRange) && TargetComp.IsValidTarget(Game::Zoe)))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Telegraph for a while, then charge in
		TelegraphEndTime = Time::GameTimeSeconds + Settings.ChargeTelegraphDuration;
		UIslandRollotronEffectHandler::Trigger_OnTelegraphCharge(Owner);
		UIslandRollotronPlayerEffectHandler::Trigger_OnTelegraphCharge(Game::Zoe);
		UIslandRollotronPlayerEffectHandler::Trigger_OnTelegraphCharge(Game::Mio);

		auto AudioManager = TListedActors<AAIIslandRollotronAudioManagerActor>().GetSingle();
		UIslandRollotronEffectHandler::Trigger_OnRollotronSpikesOut(AudioManager, FRollotronEventParams(Cast<AAIIslandRollotron>(Owner)));
		UIslandRollotronPlayerEffectHandler::Trigger_OnRollotronSpikesOut(Game::Zoe, FRollotronPlayerEventParams(Cast<AAIIslandRollotron>(Owner)));
		UIslandRollotronPlayerEffectHandler::Trigger_OnRollotronSpikesOut(Game::Mio, FRollotronPlayerEventParams(Cast<AAIIslandRollotron>(Owner)));

		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandRollotronEffectHandler::Trigger_OnChargeEnd(Owner);
		UIslandRollotronPlayerEffectHandler::Trigger_OnChargeEnd(Game::Zoe);
		UIslandRollotronPlayerEffectHandler::Trigger_OnChargeEnd(Game::Mio);
		
		UIslandRollotronEffectHandler::Trigger_OnDetonated(Owner);
		UIslandRollotronPlayerEffectHandler::Trigger_OnDetonated(Game::Zoe);
		UIslandRollotronPlayerEffectHandler::Trigger_OnDetonated(Game::Mio);
		SpikeComp.bIsJumping = false;

		auto AudioManager = TListedActors<AAIIslandRollotronAudioManagerActor>().GetSingle();
		UIslandRollotronEffectHandler::Trigger_OnRollotronDetonate(AudioManager, FRollotronEventParams(Cast<AAIIslandRollotron>(Owner)));

		// Kill self
		HealthComp.TakeDamage(1.0, EDamageType::Explosion, Owner);

		// Deal damage
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Owner.ActorCenterLocation.IsWithinDist(Player.ActorCenterLocation, Settings.ExplosionDamageRange))
				continue;

			Player.DealTypedDamage(Owner, Settings.ExplosionDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
		}
		

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.ExplosionDamageRange, LineColor = FLinearColor::Red, Duration = 1.0);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds < TelegraphEndTime)
			TelegraphDetonation();		
	}
	
	void TelegraphDetonation()
	{
		SpikeComp.bIsJumping = true;
	}

}

