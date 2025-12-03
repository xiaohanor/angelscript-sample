class USummitMagePlateComponent : UActorComponent
{
	AHazeActor HazeOwner;
	private FName Team = n"SummitPlateUser";
	AHazeActor TargetPlate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");

		HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.JoinTeam(Team, USummitMagePlateUserTeam);
	}

	UFUNCTION()
	private void OnReset()
	{
		HazeOwner.JoinTeam(Team, USummitMagePlateUserTeam);
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		TargetPlate = nullptr;
		HazeOwner.LeaveTeam(Team);
	}
}