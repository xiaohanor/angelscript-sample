struct FSanctuaryMedallionHydraAnimationActionParams
{
	EFeatureTagMedallionHydra Tag;
	EFeatureSubTagMedallionHydra SubTag;
	float CustomDuration = -1.0;
}

class USanctuaryMedallionHydraAnimationCapability : UHazeActionQueueCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 102;

	FSanctuaryMedallionHydraAnimationActionParams QueueParameters;
	USanctuaryBossMedallionHydraAnimComponent AnimationComponent;
	ASanctuaryBossMedallionHydra Hydra;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		AnimationComponent = USanctuaryBossMedallionHydraAnimComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryMedallionHydraAnimationActionParams Parameters)
	{
		QueueParameters = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Hydra.bIsControlledByCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Hydra.bIsControlledByCutscene)
			return true;
		if (ActiveDuration > AnimationComponent.GetAnimationDuration())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AnimationComponent.RequestAnimation(QueueParameters.Tag, QueueParameters.SubTag, QueueParameters.CustomDuration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Hydra.ShouldIdle())
		{
			AnimationComponent.RequestAnimation(EFeatureTagMedallionHydra::None_Idling, EFeatureSubTagMedallionHydra::None);
		}
	}

};