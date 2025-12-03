struct FWalkerSuspendedCableCutBehaviourParams
{
	FName Reaction;
}

class UIslandWalkerSuspendedCableCutBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	AIslandWalkerCablesTarget FrontCablesTarget = nullptr;
	UIslandWalkerSettings Settings;

	float CableCutTime = -BIG_NUMBER;
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
		Target.OnBreak.AddUFunction(this, n"OnCableCut");
		if (FrontCablesTarget == nullptr)
			FrontCablesTarget = Target;
		else if (Owner.ActorForwardVector.DotProduct(Target.ActorLocation - FrontCablesTarget.ActorLocation) > 0.0)
			FrontCablesTarget = Target;
	}

	UFUNCTION()
	private void OnCableCut(AIslandWalkerCablesTarget Target)
	{
		CableCutTime = Time::GameTimeSeconds;
		if (Target == FrontCablesTarget)
			Reaction = SubTagWalkerSuspended::FrontCablesCut;
		else
			Reaction = SubTagWalkerSuspended::RearCablesCut;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWalkerSuspendedCableCutBehaviourParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(CableCutTime) > 0.5)
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
	void OnActivated(FWalkerSuspendedCableCutBehaviourParams Params)
	{
		Super::OnActivated();
		Reaction = Params.Reaction;
		AnimDuration = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::Suspended, Reaction).PlayLength;
		AnimComp.RequestFeature(FeatureTagWalker::Suspended, Reaction, EBasicBehaviourPriority::High, this);

		bool bRearCable = (Reaction == SubTagWalkerSuspended::RearCablesCut);
		if (bRearCable) 
			WalkerComp.bRearCableCut = true;
		else
			WalkerComp.bFrontCableCut = true;

		bool bBroken = false;
		for (AIslandWalkerSuspensionCable Cable : WalkerComp.DeployedCables)
		{
			if (bRearCable == (Cable.CouplingComp.Owner != FrontCablesTarget))
			{
				if (!bBroken)
					Cable.Break();
				else 
					Cable.Weaken();
				bBroken = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		CableCutTime = -BIG_NUMBER;
	}
}
