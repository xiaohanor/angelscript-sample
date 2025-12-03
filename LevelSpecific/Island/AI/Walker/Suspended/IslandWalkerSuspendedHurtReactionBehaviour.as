struct FWalkerSuspendedHurtReactionBehaviourParams
{
	FName Reaction;
}

class UIslandWalkerSuspendedHurtReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	AIslandWalkerCablesTarget FrontCablesTarget = nullptr;
	UIslandWalkerSettings Settings;

	float HurtTime = -BIG_NUMBER;
	FName Reaction = NAME_None;
	float AnimDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::GetOrCreate(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);

		TArray<UIslandWalkerCablesTargetRoot> CablesTargetRoots;
		Owner.GetComponentsByClass(CablesTargetRoots);
		for (UIslandWalkerCablesTargetRoot Root : CablesTargetRoots)
		{
			Root.OnCablesTargetSetup.AddUFunction(this, n"OnTargetSetup");
		}
	}

	UFUNCTION()
	private void OnTargetSetup(AIslandWalkerCablesTarget Target)
	{
		Target.OnTakeDamage.AddUFunction(this, n"OnCablesTakeDamage");

		if (FrontCablesTarget == nullptr)
			FrontCablesTarget = Target;
		else if (Owner.ActorForwardVector.DotProduct(Target.ActorLocation - FrontCablesTarget.ActorLocation) > 0.0)
			FrontCablesTarget = Target;
	}

	UFUNCTION()
	private void OnCablesTakeDamage(AIslandWalkerCablesTarget Target)
	{
		HurtTime = Time::GameTimeSeconds;
		if (Target == FrontCablesTarget)
			Reaction = SubTagWalkerSuspended::FrontHurtReaction;
		else
			Reaction = SubTagWalkerSuspended::RearHurtReaction;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWalkerSuspendedHurtReactionBehaviourParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(HurtTime) > 0.5)
			return false;
		OutParams.Reaction = Reaction;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > AnimDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWalkerSuspendedHurtReactionBehaviourParams Params)
	{
		Super::OnActivated();
		Reaction = Params.Reaction;
		AnimDuration = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::Suspended, Reaction).PlayLength;
		AnimComp.RequestFeature(FeatureTagWalker::Suspended, Reaction, EBasicBehaviourPriority::High, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HurtTime = -BIG_NUMBER;
	}
}
