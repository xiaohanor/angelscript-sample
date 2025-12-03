class USanctuaryDoppelGangerWatsonPortBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USanctuaryDoppelgangerSettings DoppelSettings;
	USanctuaryDoppelgangerComponent DoppelComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		DoppelComp = USanctuaryDoppelgangerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DoppelComp.MimicState != EDoppelgangerMimicState::WantsFullMimic)
			return false;
		if (DoppelComp.MimicTarget == nullptr)
			return false;
		
		// Only teleport if we, and the position we want to teleport to, 
		// is out of view of the player we're trying to fool
		AHazePlayerCharacter FooledPlayer = DoppelComp.MimicTarget.OtherPlayer;
		if (SceneView::IsInView(FooledPlayer, Owner.ActorCenterLocation, FVector2D(-0.2, 1.2), FVector2D(-0.2, 1.2)))
			return false;
		if (SceneView::IsInView(FooledPlayer, DoppelComp.GetMimicLocation(), FVector2D(-0.2, 1.2), FVector2D(-0.2, 1.2)))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		// Single activation only!
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		FTransform MimicTransform = (DoppelComp.MimicTarget.ActorTransform * DoppelComp.MimicTargetInverseTransform) * DoppelComp.MimicTransform;
		DoppelComp.DoppelTransform = MimicTransform;
		DoppelComp.MimicState = EDoppelgangerMimicState::FullMimic;
	}
}


