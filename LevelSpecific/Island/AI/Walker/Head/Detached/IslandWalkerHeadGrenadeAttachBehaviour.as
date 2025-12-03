struct FWalkerHeadGrenadeReactionBehaviourParam
{
	bool bLeftReaction;
}

// Only used when we have grenade locks
class UIslandWalkerHeadGrenadeAttachBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerAnimationComponent HeadAnimComp;
	TArray<UIslandWalkerGrenadeLockRootComponent> LockRootComps;
	float AttachTime = -BIG_NUMBER;
	float ReactionDuration;
	AIslandGrenadeLock LastHitLock;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		Owner.GetComponentsByClass(LockRootComps);
		HeadAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		for (UIslandWalkerGrenadeLockRootComponent LockRoot : LockRootComps)
		{
			LockRoot.OnGrenadeProperlyAttached.AddUFunction(this, n"OnGrenadeProperlyAttached");
		}
	}

	UFUNCTION()
	private void OnGrenadeProperlyAttached(AIslandGrenadeLock Lock)
	{
		AttachTime = Time::GameTimeSeconds;
		LastHitLock = Lock;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWalkerHeadGrenadeReactionBehaviourParam& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(AttachTime) > 0.5)
			return false;
		OutParams.bLeftReaction = (Owner.ActorRightVector.DotProduct(LastHitLock.ActorLocation - Owner.ActorLocation) < 0.0);
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
		AttachTime = -BIG_NUMBER;
	}
};