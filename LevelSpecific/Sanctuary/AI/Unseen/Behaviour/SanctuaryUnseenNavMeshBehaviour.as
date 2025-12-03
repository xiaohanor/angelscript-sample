class USanctuaryUnseenNavMeshBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	USanctuaryUnseenSettings UnseenSettings;
	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryUnseenChaseComponent ChaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		UnseenSettings = USanctuaryUnseenSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		ChaseComp = USanctuaryUnseenChaseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(ChaseComp.CanChase(TargetComp.Target))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(Player != nullptr)
			TargetComp.SetTarget(Player.OtherPlayer);
	}
}

