class USummitKnockdownBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UBasicAIKnockdownComponent KnockdownComp;
	ABasicAICharacter AICharacter;
	bool bShouldReact = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnockdownComp = UBasicAIKnockdownComponent::GetOrCreate(Owner);
		AICharacter = Cast<ABasicAICharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if (!KnockdownComp.HasKnockdown())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!KnockdownComp.HasKnockdown())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AICharacter.MeshOffsetComponent.SetRelativeRotation(FRotator(90.0, 0.0, 0.0));

		// 	Request hurt of suitable type. No mh expected, so single request will do.
		//	Replace with Knockdown Reactions
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Default, EBasicBehaviourPriority::High, this, BasicSettings.HurtDuration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AICharacter.MeshOffsetComponent.SetRelativeRotation(FRotator(0.0, 0.0, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > BasicSettings.KnockdownDuration)
		{
			AnimComp.Reset();
			TargetComp.SetTarget(nullptr); // Select a new target
			KnockdownComp.ConsumeKnockdown();
			return;
		}
	}
}