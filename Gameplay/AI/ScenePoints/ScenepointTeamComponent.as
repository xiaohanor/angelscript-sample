// Auxiliary component for scenepoints which should only be usable by members of a specific team
class UScenepointTeamComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Team")
	FName Team = AITeams::Default;	
}

