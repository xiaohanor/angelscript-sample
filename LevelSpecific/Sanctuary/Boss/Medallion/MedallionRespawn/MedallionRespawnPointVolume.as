class AMedallionRespawnPointVolume : ARespawnPointVolume
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly, Category = "RespawnPoints")
	EMedallionPhase EnabledPhase;
};