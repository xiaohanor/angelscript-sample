class USummitKnightHeadDamagedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"HurtReaction");
	default TickGroup = EHazeTickGroup::Gameplay;

	USummitKnightStageComponent StageComp;
	UBasicAIAnimationComponent AnimComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	USummitKnightSettings Settings;
	float AnimDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StageComp = USummitKnightStageComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Owner.GetComponentsByClass(Blades);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (StageComp.Phase != ESummitKnightPhase::HeadDamage)
			return false;
		if ((StageComp.Round < 1) && (StageComp.Round >= Settings.DestroyHeadHits))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Only abort when done or by testing phase
		if (StageComp.Phase == ESummitKnightPhase::Test)
			return true;
		if (ActiveDuration > AnimDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		// AnimDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalSmashDamage, Settings.DamageHeadDuration);
		// AnimComp.RequestFeature(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalSmashDamage, EBasicBehaviourPriority::Medium, this, AnimDuration);		

		Sceptre.Unequip();
		Blades[0].Equip();
		Blades[1].Equip();

		auto Head = USummitKnightHeadComponent::Get(Owner);
		Head.DamageHead();
		//USummitKnightEventHandler::Trigger_OnDamageHead(Owner, FSummitKnightHeadDamageParams(Head));

		auto HealthComp = UBasicAIHealthComponent::Get(Owner);
		if (HealthComp.CurrentHealth > 0.33)
			HealthComp.TakeDamage(HealthComp.CurrentHealth - 0.33, EDamageType::MeleeBlunt, Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		AnimComp.ClearFeature(this);

		Sceptre.Equip();
		Blades[0].Unequip();
		Blades[1].Unequip();

		if (StageComp.Phase != ESummitKnightPhase::Test)
		{
			StageComp.SetPhase(ESummitKnightPhase::FinalArenaEnd, 1);
		}
	}
};