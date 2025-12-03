class UIslandJetpackPhasableComponent : UActorComponent
{	
	bool bQueuedPhasableSlowdown = false;
	AIslandPhasablePlatformSpline PhasablePlatformSpline;
	FHazeAcceleratedFloat AccFOV;
};