
// The given actor will join a team of the given name, with optional specific class. Returns the team that was joined or null if team couldn't be joined. 
UFUNCTION(Category = "Team")
mixin UHazeTeam JoinTeam(AHazeActor TeamMember, FName TeamName, TSubclassOf<UHazeTeam> TeamClass = nullptr)
{
	UHazeTeamManager Manager = Game::GetSingleton(UHazeTeamManager);
	return Manager.JoinTeam(TeamMember, TeamName, TeamClass);
}

// Will return a team if the given actor already is a member, nullptr otherwise
UFUNCTION(Category = "Team")
mixin UHazeTeam GetJoinedTeam(AHazeActor TestMember, FName TeamName)
{
	UHazeTeamManager Manager = Game::GetSingleton(UHazeTeamManager);
	return Manager.GetJoinedTeam(TestMember, TeamName);
}

UFUNCTION(Category = "Team")
mixin void LeaveTeam(AHazeActor TeamMember, FName TeamName)
{
	UHazeTeamManager Manager = Game::GetSingleton(UHazeTeamManager);
	Manager.LeaveTeam(TeamMember, TeamName);
}

namespace HazeTeam
{
	// Will return a team if there is one with given name or nullptr otherwise
	UFUNCTION(Category = "Team")
	UHazeTeam GetTeam(FName TeamName)
	{
		UHazeTeamManager Manager = Game::GetSingleton(UHazeTeamManager);
		return Manager.GetTeam(TeamName);
	}
}
	
