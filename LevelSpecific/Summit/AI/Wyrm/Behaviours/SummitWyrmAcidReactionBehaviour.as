
class USummitWyrmAcidReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UAcidResponseComponent AcidResponseComp;
	UBasicAIHealthComponent HealthComp;
	USummitWyrmTailComponent TailComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		TailComp = USummitWyrmTailComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Params)
	{
		auto HitSegment = Cast<USummitWyrmTailSegmentComponent>(Params.HitComponent);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!HealthComp.IsDead())
			return false;

		// Wip
		return false;
		//return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

	}
}