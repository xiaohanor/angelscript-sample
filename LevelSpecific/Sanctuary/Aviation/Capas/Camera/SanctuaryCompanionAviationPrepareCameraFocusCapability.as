class USanctuaryCompanionAviationPrepareCameraFocusCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default CapabilityTags.Add(AviationCapabilityTags::AviationPrepareCameraFocus);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	ASanctuaryBossArenaManager ArenaManager;
	ASanctuaryCompanionAviationToAttackCameraFocusActor ToAttackFocusActorMio;
	ASanctuaryCompanionAviationToAttackCameraFocusActor ToAttackFocusActorZoe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
			ArenaManager = BossManagers[0];
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.HasDestination())
			return false;

		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.HasDestination())
			return true;

		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (ToAttackFocusActorMio == nullptr || ToAttackFocusActorZoe == nullptr)
		{
			ToAttackFocusActorMio = ArenaManager.ToAttackFocusActorMio;
			ToAttackFocusActorZoe = ArenaManager.ToAttackFocusActorZoe;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHitResult Unused;
		FVector FocusPoint = Owner.ActorLocation;
		if (Player.IsMio() && ToAttackFocusActorMio != nullptr)
			ToAttackFocusActorMio.SetControlDesiredLocation(FocusPoint);
		else if (ToAttackFocusActorZoe != nullptr)
			ToAttackFocusActorZoe.SetControlDesiredLocation(FocusPoint);
	}
};

