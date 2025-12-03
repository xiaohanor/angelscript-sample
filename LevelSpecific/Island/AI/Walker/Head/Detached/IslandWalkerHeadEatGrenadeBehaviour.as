class UIslandWalkerHeadEatGrenadeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerAnimationComponent HeadAnimComp;
	UIslandRedBlueTargetableComponent EatGrenadeTargetComp;

	float EatDuration; 
	float DetonateDuration;
	float DetonateTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		HeadAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		 
		EatGrenadeTargetComp = UIslandRedBlueTargetableComponent::Get(Owner, n"EatGrenadeTargetComp");
	
		// TODO: Can't hide widget or set widget to something invisible currently, disable until fixed.
		EatGrenadeTargetComp.Disable(this); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWalkerHeadGrenadeReactionBehaviourParam& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > EatDuration + DetonateDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWalkerHeadGrenadeReactionBehaviourParam Params)
	{
		Super::OnActivated();
		EatDuration = HeadAnimComp.GetRequestedAnimation(FeatureTagWalker::HeadGrenadeReaction, SubTagWalkerHeadGrenadeReaction::Eat).PlayLength;
		AnimComp.RequestFeature(FeatureTagWalker::HeadGrenadeReaction, SubTagWalkerHeadGrenadeReaction::Eat, EBasicBehaviourPriority::Medium, this);

		UAnimSequence DetonateAnim = HeadAnimComp.GetRequestedAnimation(FeatureTagWalker::HeadGrenadeReaction, SubTagWalkerHeadGrenadeReaction::EatenDetonate);
		DetonateDuration = DetonateAnim.PlayLength;
		DetonateTime = EatDuration + DetonateAnim.GetAnimNotifyStateStartTime(UBasicAIActionAnimNotify);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((ActiveDuration > EatDuration) && (AnimComp.SubFeatureTag != SubTagWalkerHeadGrenadeReaction::EatenDetonate))
			AnimComp.RequestSubFeature(SubTagWalkerHeadGrenadeReaction::EatenDetonate, this);

		if (ActiveDuration > DetonateTime)
		{
			// TODO: Detonate eaten grenade
			DetonateTime = BIG_NUMBER;
		}
	}
};
