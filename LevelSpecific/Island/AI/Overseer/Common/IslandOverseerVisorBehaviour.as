
class UIslandOverseerVisorBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerVisorComponent VisorComp;

	float WaitDuration = 1;
	bool bOpened;
	bool bReopen = true;
	
	UIslandOverseerVisorBehaviour(bool bDoReopen)
	{
		bReopen = bDoReopen;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		VisorComp = UIslandOverseerVisorComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > VisorComp.OpenDuration + VisorComp.CloseDuration + WaitDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bOpened = false;
		if(VisorComp.bOpen)
			VisorComp.Close();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!bReopen)
			return;

		if(!bOpened && ActiveDuration > WaitDuration + VisorComp.CloseDuration)
		{
			bOpened = true;
			VisorComp.Open();
		}
	}
}