class UHoverPerchComponent : UActorComponent
{
	bool bIsGrinding = false;
	bool bIsDestroyed = false;
	bool bHasHasImpactSincePerching = false;
	
	float TimeLastBumpedOtherPerch = -MAX_flt;
	float TimeLastStoppedGrinding = -MAX_flt;

	AHazePlayerCharacter PerchingPlayer;
};