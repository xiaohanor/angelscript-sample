class UDarkPortalReactionTeam : UHazeTeam
{
	TArray<AHazeActor> Grabbed;
	private int MaxGrabbed = 3;

	void Grab(AHazeActor Member)
	{
		// We update MaxGrabbed here since there's no good designer friendly place for this setting other than the actors
		auto ReactionSettings = USanctuaryReactionSettings::GetSettings(Member);
		MaxGrabbed = ReactionSettings.MaxGrabTargets;

		Grabbed.AddUnique(Member);
		UpdateComponents();
	}

	void Release(AHazeActor Member)
	{
		// We update MaxGrabbed here since there's no good designer friendly place for this setting other than the actors
		auto ReactionSettings = USanctuaryReactionSettings::GetSettings(Member);
		MaxGrabbed = ReactionSettings.MaxGrabTargets;

		Grabbed.RemoveSingle(Member);
		UpdateComponents();
	}

	void UpdateComponents()
	{
		for(AHazeActor Member: GetMembers())
		{
			if(Grabbed.Contains(Member))
				continue;

			auto TargetComp = UDarkPortalTargetComponent::Get(Member);
			if(Grabbed.Num() >= MaxGrabbed)
				TargetComp.Disable(this);
			else 
				TargetComp.Enable(this);
		}
	}
}