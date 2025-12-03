struct FDentistBossDrillImpaleCakeActivationParams
{
	float ImpaleDuration;
}

class UDentistBossDrillImpaleCakeCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossDrillImpaleCakeActivationParams Params;

	ADentistBoss Dentist;
	ADentistBossCake Cake;
	ADentistBossToolDrill Drill;

	const float CakeDownOffset = 500.0;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Drill = Cast<ADentistBossToolDrill>(Dentist.Tools[EDentistBossTool::Drill]);
		Cake = Dentist.Cake;
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossDrillImpaleCakeActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Params.ImpaleDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = Drill.ActorLocation;
		Dentist.bDrillSpinArena = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};