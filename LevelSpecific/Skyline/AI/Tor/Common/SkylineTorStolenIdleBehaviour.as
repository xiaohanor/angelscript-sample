class USkylineTorStolenIdleBehaviour : UBasicBehaviour
{
	// Target need only be set on control side
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineTorSettings::GetSettings(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		
		auto MusicManager = UHazeAudioMusicManager::Get();
		if(MusicManager != nullptr)
		{
			MusicManager.OnMainMusicBeat().AddUFunction(this, n"OnMusicBeat");
		}

		SkylineTorDevToggleNamespace::DontRecallHammer.MakeVisible();
	}

	UFUNCTION()
	private void OnMusicBeat()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (HoldHammerComp.Hammer.HammerComp.CurrentMode != ESkylineTorHammerMode::Stolen)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > 6 && !SkylineTorDevToggleNamespace::DontRecallHammer.IsEnabled())
		{
			HoldHammerComp.Hammer.HammerComp.Recall();
			DeactivateBehaviour();
		}
	}
}
