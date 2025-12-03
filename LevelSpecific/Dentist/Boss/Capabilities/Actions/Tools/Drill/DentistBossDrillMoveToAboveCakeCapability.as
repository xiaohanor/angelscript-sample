struct FDentistBossDrillMoveToAboveCakeActivationParams
{
	float MoveToCakeDuration;
}

class UDentistBossDrillMoveToAboveCakeCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossDrillMoveToAboveCakeActivationParams Params;

	ADentistBoss Dentist;
	ADentistBossCake Cake;
	ADentistBossToolDrill Drill;

	const float CakeUpOffset = 500.0;

	FRotator StartRotation;
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Drill = Cast<ADentistBossToolDrill>(Dentist.Tools[EDentistBossTool::Drill]);
		Cake = Dentist.Cake;
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossDrillMoveToAboveCakeActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Params.MoveToCakeDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartRotation = Drill.ActorRotation;
		StartLocation = Drill.ActorLocation;

		Drill.bIsDirected = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Drill.ActorLocation = TargetLocation;
		Drill.ActorRotation = TargetRotation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / Params.MoveToCakeDuration;
		Drill.ActorLocation = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Drill.ActorRotation = Math::LerpShortestPath(StartRotation, TargetRotation, Alpha);
	}

	FRotator GetTargetRotation() const property
	{
		return FRotator::MakeFromXZ(FVector::DownVector, Dentist.ActorRightVector);
	}

	FVector GetTargetLocation() const property
	{
		return Cake.ActorLocation + FVector::UpVector * CakeUpOffset;
	}
};