class UPrisonGuardComponent : UActorComponent
{
	UHazeTeam Team = nullptr;

	float LastDroneHitTime = -BIG_NUMBER;

	UHazeTeam JoinTeam()
	{
		if (Team == nullptr)
			Team = Cast<AHazeActor>(Owner).JoinTeam(n"PrisonGuardTeam");
		return Team;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Cast<AHazeActor>(Owner).LeaveTeam(n"PrisonGuardTeam");
	}

	void HitByDrone()
	{
		LastDroneHitTime = Time::GameTimeSeconds;
	}
}
