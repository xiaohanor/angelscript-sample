namespace Traversal
{
	UTraversalManager GetManager()
	{
		return Cast<UTraversalManager>(HazeTeam::GetTeam(TraversalArea::TeamName));
	}

	bool IsTraversable(FVector Start, FVector End)
	{
		// TODO: We need to access Recast's heightfields to be able to check 
		// more cheaply and dependably if we can traverse from one position to another.
		// Use traces meanwhile.
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.SetTraceComplex(false);
		Trace.UseLine();
		FHitResult Obstruction = Trace.QueryTraceSingle(Start, End);
		return !Obstruction.bBlockingHit;	
	}

	FVector GetLaunchDirection(FRotator BaseRot, float Pitch)
	{
		FRotator Rot = BaseRot;
		Rot.Pitch = Pitch;
		return Rot.Vector();		
	}

	FVector GetLandDirection(FRotator BaseRot, float Pitch)
	{
		return -GetLaunchDirection(BaseRot, Pitch);
	}
}


