struct FIslandWalkerLegHurtParams
{
	FName HurtReaction;
}


class UIslandWalkerLegHurtBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerSwivelComponent Swivel;
	UIslandWalkerSettings Settings;
	FName PendingHurtReaction = NAME_None;
	float ReactionDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandWalkerSettings::GetSettings(Owner); 
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		LegsComp.OnLegDestroyed.AddUFunction(this, n"OnLegDestroyed");
	}

	UFUNCTION()
	private void OnLegDestroyed(AIslandWalkerLegTarget Leg)
	{
		if (Owner.ActorRightVector.DotProduct(Leg.ActorLocation - Owner.ActorLocation) < 0.0)
			PendingHurtReaction = SubTagWalkerHit::Right; // Twitch to the right when left leg is destroyed
		else
			PendingHurtReaction = SubTagWalkerHit::Left;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandWalkerLegHurtParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(PendingHurtReaction.IsNone())
			return false;
		if(LegsComp.bIsUnbalanced)
			return false; // Time to fall instead
		OutParams.HurtReaction = PendingHurtReaction;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > ReactionDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandWalkerLegHurtParams Params)
	{
		Super::OnActivated();
		PendingHurtReaction = Params.HurtReaction;
		ReactionDuration = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::Hit, PendingHurtReaction, Settings.LegDestroyedHurtDuration);
		AnimComp.RequestFeature(FeatureTagWalker::Hit, PendingHurtReaction, EBasicBehaviourPriority::High, this);

		PendingHurtReaction = NAME_None;
		WalkerComp.LaserAttackCount = 0;
		WalkerComp.FireBurstCount = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Swivel.Realign(ReactionDuration * 0.5, DeltaTime);	
	}
}