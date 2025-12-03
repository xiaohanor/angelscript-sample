class UPlayerChestLauncherCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketMimic Mimic;
	UMoonMarketMimicPlayerComponent LaunchComp;

	float InternalLaunchTime = 1.0;
	bool bHaveReleased;

	FVector TongueStartLoc;
	FRotator TongueStartRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LaunchComp = UMoonMarketMimicPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!LaunchComp.bLaunchReady)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > InternalLaunchTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Mimic = LaunchComp.CurrentMimic;
		bHaveReleased = false;
		Mimic.BP_PlayReleaseTimeline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mimic.FinishLaunch();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / InternalLaunchTime;

		if (Alpha > 0.35 && !bHaveReleased)
		{
			LaunchComp.bEaten = false;
			Player.DetachFromActor(EDetachmentRule::KeepWorld);
			Player.UnblockCapabilities(CapabilityTags::Movement, LaunchComp);
			Player.UnblockCapabilities(CapabilityTags::Visibility, LaunchComp);
			Player.SetActorLocation(Mimic.ActorLocation + FVector::UpVector * 100);
			Player.RemoveTutorialPromptByInstigator(LaunchComp);
			Player.DeactivateCameraByInstigator(LaunchComp.CurrentMimic, 3.0);
			LaunchComp.bLaunchReady = false;
			Player.AddMovementImpulse(LaunchComp.CurrentMimic.GetLaunchVelocity());
			bHaveReleased = true;
			Mimic.OnPlayerLaunched();
		}
	}
};