class USummitCrystalSkullsTeam : UHazeTeam
{
	AHazeActor Boss;
	AHazeActor RightWing; 
	AHazeActor LeftWing; 
}

namespace CrystalSkullsTeam
{
	const FName Name = n"CrystalSkulls";

	USummitCrystalSkullsTeam Join(AHazeActor Member)
	{
		return Cast<USummitCrystalSkullsTeam>(Member.JoinTeam(Name, USummitCrystalSkullsTeam));
	}
}
