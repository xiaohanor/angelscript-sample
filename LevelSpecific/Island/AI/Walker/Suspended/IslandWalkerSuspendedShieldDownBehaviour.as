struct FWalkerSuspendedShieldDownBehaviourParams
{
	FName Reaction;
}

class UIslandWalkerSuspendedShieldDownBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	AIslandWalkerCablesTarget FrontCablesTarget = nullptr;
	UIslandWalkerSettings Settings;

	float ShieldDownTime = -BIG_NUMBER;
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
		Target.ForceFieldComp.OnDepleted.AddUFunction(this, n"OnForceFieldDepleted");
		if (FrontCablesTarget == nullptr)
			FrontCablesTarget = Target;
		else if (Owner.ActorForwardVector.DotProduct(Target.ActorLocation - FrontCablesTarget.ActorLocation) > 0.0)
			FrontCablesTarget = Target;
	}

	UFUNCTION()
	private void OnForceFieldDepleted(UIslandWalkerForceFieldComponent ForceFieldComponent)
	{
		ShieldDownTime = Time::GameTimeSeconds;
		if (ForceFieldComponent.Owner == FrontCablesTarget)
			Reaction = SubTagWalkerSuspended::FrontShieldDown;
		else
			Reaction = SubTagWalkerSuspended::RearShieldDown;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWalkerSuspendedShieldDownBehaviourParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(ShieldDownTime) > 0.5)
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
	void OnActivated(FWalkerSuspendedShieldDownBehaviourParams Params)
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
		ShieldDownTime = -BIG_NUMBER;
	}
}
