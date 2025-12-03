struct FCoastBossGunChangeMovementActionParams
{
	ECoastBossMovementMode NewMode;
}

class UCoastBossGunChangeMovementCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	FCoastBossGunChangeMovementActionParams QueueParameters;
	ACoastBoss Boss;
	ACoastBossActorReferences References;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FCoastBossGunChangeMovementActionParams Parameters)
	{
		QueueParameters = Parameters;
		if (References == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			References = Refs.Single;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < KINDA_SMALL_NUMBER)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.GunBossMovementMode = QueueParameters.NewMode;
		FCoastBossEventHandlerMovementData Data;
		Data.MovementMode = QueueParameters.NewMode;
		UCoastBossEventHandler::Trigger_ChangedMovementMode(Boss, Data);
	}
};