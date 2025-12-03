class UIslandWalkerIntroBehaviour : UBasicBehaviour
{
	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerNeckRoot NeckRoot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);		
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		NeckRoot = UIslandWalkerNeckRoot::Get(Owner);

		// We want to always start in intro anim, but will clear it if skipping intro
		AnimComp.RequestFeature(FeatureTagWalker::Intro, EBasicBehaviourPriority::Low, this);
		PhaseComp.OnSkipIntro.AddUFunction(this, n"OnSkipIntro");
	}

	UFUNCTION()
	private void OnSkipIntro(EIslandWalkerPhase NewPhase)
	{
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (PhaseComp.Phase != EIslandWalkerPhase::Intro)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (PhaseComp.Phase != EIslandWalkerPhase::Intro)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagWalker::Intro, EBasicBehaviourPriority::Medium, this);	
		WalkerAnimComp.HeadAnim.RequestFeature(FeatureTagWalker::Intro, EBasicBehaviourPriority::Medium, this);	
		LegsComp.PowerDownLegs();
		NeckRoot.Head.PowerDown();
		Owner.AddActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	
		Owner.RemoveActorCollisionBlock(this);
		LegsComp.PowerUpLegs();
		NeckRoot.Head.PowerUp();
	}
};