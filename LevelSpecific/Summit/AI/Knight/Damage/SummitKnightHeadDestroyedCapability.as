class USummitKnightHeadDestroyedCapability : UHazeCapability
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

	float DestroyHeadTime = 0.6;
	float DestroyKnight = 2.0;

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
		if (StageComp.Round < Settings.DestroyHeadHits)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// After this, only oblivion...
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		// float Duration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalRailDamage, Settings.DestroyHeadDuration);
		// AnimComp.RequestFeature(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalRailDamage, EBasicBehaviourPriority::Medium, this, Duration);		

		Sceptre.Unequip();
		Blades[0].Equip();
		Blades[1].Equip();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		AnimComp.ClearFeature(this);

		Sceptre.AddComponentVisualsBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > DestroyHeadTime)
		{
			USummitKnightHeadComponent::Get(Owner).AddComponentVisualsBlocker(this);
			DestroyHeadTime = BIG_NUMBER;
			
			auto HealthComp = UBasicAIHealthComponent::Get(Owner);
			HealthComp.TakeDamage(HealthComp.CurrentHealth, EDamageType::MeleeBlunt, Game::Zoe);
		}
	
		if (ActiveDuration > DestroyKnight)
		{
			UHazeSkeletalMeshComponentBase::Get(Owner).AddComponentVisualsBlocker(this);
			DestroyKnight = BIG_NUMBER;
		}
	}
};