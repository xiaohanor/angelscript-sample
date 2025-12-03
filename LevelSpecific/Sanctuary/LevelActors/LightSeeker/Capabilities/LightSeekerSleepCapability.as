class ULightSeekerSleepCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightSeekerSleep");

	default TickGroup = EHazeTickGroup::Gameplay;

	ULightSeekerTargetingComponent TargetingComp;
	ALightSeeker LightSeeker;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		TargetingComp = ULightSeekerTargetingComponent::Get(LightSeeker);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!LightSeeker.HasReturned())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!LightSeeker.HasReturned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LightSeeker.bIsSleeping = true;
		LightSeeker.SkeletalMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
		ULightSeekerPlayerAssistedAirMoveComponent MioAssist = ULightSeekerPlayerAssistedAirMoveComponent::GetOrCreate(Game::Mio);
		ULightSeekerPlayerAssistedAirMoveComponent ZoeAssist = ULightSeekerPlayerAssistedAirMoveComponent::GetOrCreate(Game::Zoe);
		MioAssist.AwakeLightSeekers.Remove(LightSeeker);
		ZoeAssist.AwakeLightSeekers.Remove(LightSeeker);
		TargetingComp.SyncedDesiredHeadLocation.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
		TargetingComp.SyncedDesiredHeadRotation.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LightSeeker.bIsSleeping = false;
		//LightSeeker.bDebugging = true;
		LightSeeker.SkeletalMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
		ULightSeekerPlayerAssistedAirMoveComponent MioAssist = ULightSeekerPlayerAssistedAirMoveComponent::GetOrCreate(Game::Mio);
		ULightSeekerPlayerAssistedAirMoveComponent ZoeAssist = ULightSeekerPlayerAssistedAirMoveComponent::GetOrCreate(Game::Zoe);
		MioAssist.AwakeLightSeekers.Add(LightSeeker);
		ZoeAssist.AwakeLightSeekers.Add(LightSeeker);
		TargetingComp.SyncedDesiredHeadLocation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		TargetingComp.SyncedDesiredHeadRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

};