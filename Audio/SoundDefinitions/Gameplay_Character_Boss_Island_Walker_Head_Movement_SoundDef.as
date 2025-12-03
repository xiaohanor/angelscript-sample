
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_Head_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */
	
	bool IsSwimming(const float Offset) const 
	{
		const float HeadHeight = Head.ActorLocation.Z + Offset;
		const float SurfaceHeight = Arena.bIsFlooded ? Arena.FloodedPoolSurfaceHeight  : Arena.PoolSurfaceHeight;
		return HeadHeight < SurfaceHeight;	
	}

	AIslandWalkerHead Head;
	AIslandWalkerArenaLimits Arena;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
		Head = Cast<AIslandWalkerHead>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Head.HeadComp.State == EIslandWalkerHeadState::Attached)
			return false;

		if(IsSwimming(-250))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Head.HeadComp.State == EIslandWalkerHeadState::Attached)
			return true;

		if(IsSwimming(100))
			return true;

		return false;
	}
}