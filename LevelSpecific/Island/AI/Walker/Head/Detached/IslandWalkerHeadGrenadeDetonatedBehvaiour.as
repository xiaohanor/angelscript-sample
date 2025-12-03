class UIslandWalkerHeadGrenadeDetonatedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerAnimationComponent HeadAnimComp;
	float ForceFieldBreachedTime = -BIG_NUMBER;
	float ReactionDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		HeadAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget Target)
	{
		Target.OnForceFieldBreached.AddUFunction(this, n"OnForceFieldBreached");
	}

	UFUNCTION()
	private void OnForceFieldBreached(AHazePlayerCharacter Breacher)
	{
		ForceFieldBreachedTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWalkerHeadGrenadeReactionBehaviourParam& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(ForceFieldBreachedTime) > 0.5)
			return false;
		OutParams.bLeftReaction = Math::RandBool();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ReactionDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWalkerHeadGrenadeReactionBehaviourParam Params)
	{
		Super::OnActivated();
		FName Reaction = (Params.bLeftReaction ? SubTagWalkerHeadGrenadeReaction::HitLeft : SubTagWalkerHeadGrenadeReaction::HitRight);
		ReactionDuration = HeadAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::HeadGrenadeReaction, Reaction, 0.0);
		AnimComp.RequestFeature(FeatureTagWalker::HeadGrenadeReaction, Reaction, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ForceFieldBreachedTime = -BIG_NUMBER;
	}
};
