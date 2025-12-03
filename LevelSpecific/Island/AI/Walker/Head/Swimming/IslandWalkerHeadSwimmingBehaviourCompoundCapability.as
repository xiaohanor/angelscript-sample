class UIslandWalkerHeadSwimmingBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HeadComp.State != EIslandWalkerHeadState::Swimming)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HeadComp.State != EIslandWalkerHeadState::Swimming)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<AIslandWalkerArenaLimits>().Single.bIsFlooded = true;
		UIslandWalkerSettings::SetHeadDamagePerImpact(Owner, Settings.HeadDamagePerImpactSwim, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSelector()
				.Try(UIslandWalkerHeadSwimmingIntroBehaviour())
				.Try(UIslandWalkerHeadPoolCrashBehaviour())
				.Try(UHazeCompoundRunAll()
					.Add(UIslandWalkerHeadHurtReactionBehaviour()) 
					.Add(UHazeCompoundSelector()
						.Try(UIslandWalkerHeadFireBreachingBehaviour())
						.Try(UIslandWalkerHeadFindTargetBehaviour())
					)
					.Add(UIslandWalkerHeadSwimAroundBehaviour())
				)
			;
	}
}