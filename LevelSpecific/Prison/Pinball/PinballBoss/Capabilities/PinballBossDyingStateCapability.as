class UPinballBossDyingStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Gameplay;

	APinballBoss Boss;
	float LastExplodeTime = -1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APinballBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.BossState != EPinballBossState::Dying)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.BossState != EPinballBossState::Dying)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.SetBossState(EPinballBossState::Dying);

		LastExplodeTime = Time::GameTimeSeconds;
		Boss.BallMeshComp.SetHiddenInGame(true);
		SpawnActor(APinballBossBall,Boss.BallMeshComp.WorldLocation,Boss.BallMeshComp.WorldRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector EndOfDeathSpline = Boss.DeathSpline.Spline.GetWorldLocationAtSplineFraction(1.0);
		if(Boss.ActorLocation.Equals(EndOfDeathSpline, 100))
			return;

		const float DistanceAlongSpline = Boss.DeathSpline.Spline.GetClosestSplineDistanceToWorldLocation(Boss.ActorLocation);
		const FVector CurrentLocation = Boss.DeathSpline.Spline.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
		const FVector TargetLocation = Boss.DeathSpline.Spline.GetWorldLocationAtSplineDistance(DistanceAlongSpline + 100);
		const FVector Location = Math::VInterpTo(CurrentLocation, TargetLocation, DeltaTime, 10);

		Boss.SetActorLocation(Location);

		const FRotator TargetRotation = FRotator::MakeFromX(Game::Zoe.ActorLocation - Boss.ActorLocation);
		const FRotator Rotation = Math::RInterpTo(Boss.ActorRotation, TargetRotation, DeltaTime, 2);
		Boss.SetActorRotation(Rotation);

		if(Time::GetGameTimeSince(LastExplodeTime) > 0.5)
		{
			UPinballBossEventHandler::Trigger_DyingExplosion(Boss);
			LastExplodeTime = Time::GameTimeSeconds;
		}
	}
};