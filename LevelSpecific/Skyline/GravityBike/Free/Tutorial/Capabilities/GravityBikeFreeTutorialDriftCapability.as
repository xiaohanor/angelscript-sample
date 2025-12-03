class UGravityBikeFreeTutorialDriftCapability : UTutorialCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GravityBikeFreeTutorial");
	default CapabilityTags.Add(n"GravityBikeFreeTutorialDrift");

	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeFreeKartDriftComponent DriftComp;
	UGravityBikeFreeTutorialUserComponent TutorialComp;

	bool bTutorialCompleted = false;
	float DriftTimeStamp = 0.0;
	float DriftReminderTime = 25.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bTutorialCompleted)
			return false;

	//	if (Time::GameTimeSeconds < DriftTimeStamp + DriftReminderTime)
	//		return false;

		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DriftComp.IsDrifting())
			return true;

		return Super::ShouldDeactivate();;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TutorialComp = UGravityBikeFreeTutorialUserComponent::Get(Owner);
		DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);

		Player.ShowTutorialPromptWorldSpace(TutorialComp.PromptDrift, this, Owner.RootComponent, TutorialComp.AttachOffset, TutorialComp.ScreenSpaceOffset);
//		Player.ShowTutorialPrompt(TutorialComp.PromptDrift, this);

		bTutorialCompleted = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (DriverComp == nullptr)
		{
			DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);
			return;
		}

		if (DriftComp == nullptr)
		{
			DriftComp = UGravityBikeFreeKartDriftComponent::Get(DriverComp.GetGravityBike());
			return;
		}

		if(DriftComp.IsDrifting())
			DriftTimeStamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};