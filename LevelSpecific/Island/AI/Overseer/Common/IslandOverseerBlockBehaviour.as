
class UIslandOverseerBlockBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandOverseerSettings Settings;
	UAnimInstanceIslandOverseer AnimInstance;

	FBasicAIAnimationActionDurations Durations;
	AHazeCharacter Character;
	float ImpactTime;
	float Duration = 0.25;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Character.Mesh.AnimInstance);

		auto Response = UIslandRedBlueImpactResponseComponent::Get(Owner);
		Response.OnImpactEvent.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(FIslandRedBlueImpactResponseParams Data)
	{
		ImpactTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(ImpactTime == 0)
			return false;
		if(Time::GetGameTimeSince(ImpactTime) > Duration)
			return false;
		return true;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(Time::GetGameTimeSince(ImpactTime) > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagIslandOverseer::Block, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}
}