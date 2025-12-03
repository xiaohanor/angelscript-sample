class AIslandAttackShipScenepointActor : AScenepointActorBase
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
}

class AIslandAttackShipCrashpointActor : AScenepointActorBase
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	// Crash route will go through this point on it's way towards the crashpoint location.
	UPROPERTY(DefaultComponent)
	USceneComponent CrashReroute;

	UPROPERTY(EditInstanceOnly)
	bool bIsTriggerCrashpoint = false;
	
	bool bIsUsed = false;
}