class USummitKnightLargeAreaStrikeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USummitKnightSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightComponent KnightComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		if(KnightComp.InitialAoeManager != nullptr)
		{
			KnightComp.InitialAoeManager.OnSequenceFinished.AddUFunction(this, n"OnLargeAreaStrikeSequenceComplete");
		}
	}

	UFUNCTION()
	private void OnLargeAreaStrikeSequenceComplete()
	{
		USummitKnightEventHandler::Trigger_OnLargeAreaStrikeStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (KnightComp.InitialAoeManager == nullptr)
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		USummitKnightEventHandler::Trigger_OnTelegraphLargeAreaStrike(Owner);

		KnightComp.InitialAoeManager.StartAoePattern();

		Durations.Telegraph = Settings.LargeAreaStrikeTelegraphDuration;
		Durations.Anticipation = Settings.LargeAreaStrikeAnticipationDuration;
		Durations.Action = Settings.LargeAreaStrikeActionDuration;
		Durations.Recovery = Settings.LargeAreaStrikeRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::LargeAreaStrike, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::LargeAreaStrike, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}
}

