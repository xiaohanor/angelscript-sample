class USkylineTorSetTargetBehaviour : UBasicBehaviour
{
	// Target need only be set on control side
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	USkylineTorSettings Settings;
	float LastActivationTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineTorSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.IsValidTarget(Game::Mio) && !TargetComp.IsValidTarget(Game::Zoe))
			return false;
		if (Time::GetGameTimeSince(LastActivationTime) < 0.2)
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
		LastActivationTime = Time::GameTimeSeconds;

		AHazePlayerCharacter Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Target == nullptr)
			TargetComp.SetTarget(Game::Mio);
		else
			TargetComp.SetTarget(Target.OtherPlayer);
	}

}
