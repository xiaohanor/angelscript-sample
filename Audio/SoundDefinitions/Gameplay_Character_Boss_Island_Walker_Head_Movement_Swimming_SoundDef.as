
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_Head_Movement_Swimming_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AIslandWalkerHead Head;
	AIslandWalkerArenaLimits Arena;

	const float SWIMMING_DEACTIVATION_DELAY = 2.5;
	private float DeactivationTime = 0.0;

	bool IsSwimming(const float Offset) const 
	{
		const float HeadHeight = Head.ActorLocation.Z + Offset;
		const float SurfaceHeight = Arena.bIsFlooded ? Arena.FloodedPoolSurfaceHeight  : Arena.PoolSurfaceHeight;
		return HeadHeight < SurfaceHeight;	
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Head = Cast<AIslandWalkerHead>(HazeOwner);
		Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DeactivationTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Time::GetGameTimeSince(DeactivationTime) < SWIMMING_DEACTIVATION_DELAY)
			return false;

		if(!IsSwimming(-350))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TimeActive < SWIMMING_DEACTIVATION_DELAY)
			return false;

		if(IsSwimming(50))
			return false;

		return true;
	}
}