UCLASS(Abstract)
class AMaxSecurityLaserInvisible : AMaxSecurityLaser
{
	// Default all invisible lasers to Zoe's side, since Mio won't die from them
	default NetworkMode = EMaxSecurityLaserNetwork::SyncedFromZoeControl;

	default LaserComp.bHideLaserOnStart = true;
	default LaserComp.bAutoSetBeamStartAndEnd = false;
	default LaserComp.bTraceForImpact = false;
	default LaserComp.bShowEmitter = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
};
