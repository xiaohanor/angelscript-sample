class UIslandWalkerSuspendedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandWalkerComponent WalkerComp;
	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerSwivelComponent Swivel;
	UIslandWalkerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::GetOrCreate(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Idle, EBasicBehaviourPriority::Low, this);

		HeadComp = UIslandWalkerNeckRoot::Get(Owner).Head.HeadComp;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AnimComp.FeatureTag != FeatureTagWalker::Suspended)
			AnimComp.RequestFeature(FeatureTagWalker::Suspended, SubTagWalkerSuspended::Idle, EBasicBehaviourPriority::Low, this);

		Swivel.Realign(5.0, DeltaTime);		
	}
}
