class USummitKnightMobileDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"Death");
	default TickGroup = EHazeTickGroup::Gameplay;

	UBasicAIHealthComponent HealthComp;
	USummitKnightStageComponent StageComp;
	UBasicAIAnimationComponent AnimComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightMobileCrystalBottom CrystalBottom;
	USummitKnightSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		StageComp = USummitKnightStageComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HealthComp.IsAlive())
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
		float Duration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::Death, NAME_None, Settings.DestroyHeadDuration);
		AnimComp.RequestFeature(SummitKnightFeatureTags::Death, EBasicBehaviourPriority::Medium, this, Duration);		

		CrystalBottom.Shatter();
		Cast<AAISummitKnight>(Owner).OnHeadSmashedByDragon.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		AnimComp.ClearFeature(this);
	}
};