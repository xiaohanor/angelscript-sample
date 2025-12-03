
class UHazeTeamManager : UObject
{
	private TMap<FName, UHazeTeam> Teams; 

	// The given actor will join a team of the given name, with optional specific class. Returns the team that was joined or null if team couldn't be joined. 
	UFUNCTION(Category = "Team")
	UHazeTeam JoinTeam(AHazeActor TeamMember, FName TeamName, TSubclassOf<UHazeTeam> InTeamClass = nullptr)
	{
		TSubclassOf<UHazeTeam> TeamClass = InTeamClass;
		if (TeamClass == nullptr)
			TeamClass = UHazeTeam;

		if (!devEnsure(TeamMember != nullptr, "Tried to make a null actor join team " + TeamName + " of class " + TeamClass.Get().Name))
			return nullptr;
		
		if (!IsValid(TeamMember))
			return nullptr;

		if (!Teams.Contains(TeamName))
		{
			// First member of team, register a new team
			UHazeTeam NewTeam = NewObject(this, TeamClass);
			Teams.Add(TeamName, NewTeam);
		}
		// Existing team, ensure that team class matches
		else if (!Teams[TeamName].Class.IsChildOf(TeamClass))
		{
			devError("Tried to make " + TeamMember.GetName() + " join existing team " + TeamName + " which is of class " + Teams[TeamName].Class + ", not " + TeamClass + ". The existing team was probably created by " + Teams[TeamName].GetOriginator() + " joining.");
			return nullptr;
		}

		// Welcome!
		UHazeTeam& Team = Teams[TeamName];
		Team.AddMember(TeamMember);
		return Team;
	}

	// Will return a team if the given actor already is a member, nullptr otherwise
	UFUNCTION(Category = "Team")
	UHazeTeam GetJoinedTeam(AHazeActor TestMember, FName TeamName)
	{
		if (!devEnsure(TestMember != nullptr, "Tried to get joined team for null actor. TeamName " + TeamName))
			return nullptr;

		if (!Teams.Contains(TeamName))
			return nullptr;

		if (Teams[TeamName].IsMember(TestMember))
			return nullptr;

		return Teams[TeamName];
	}

	// Will return a team if there is one with given name or nullptr otherwise
	UFUNCTION(Category = "Team")
	UHazeTeam GetTeam(FName TeamName)
	{
		if (!Teams.Contains(TeamName))
			return nullptr;

		return Teams[TeamName];
	}

	UFUNCTION(Category = "Team")
	void LeaveTeam(AHazeActor TeamMember, FName TeamName)
	{
		if (!Teams.Contains(TeamName))
			return;
		
		// Bye!
		UHazeTeam& Team = Teams[TeamName];
		Team.RemoveMember(TeamMember);

		// Remove team if no more members
		if (Team.GetMembers().Num() == 0)
			Teams.Remove(TeamName);	
	}
}
