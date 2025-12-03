// Island has custom contextual moves because traces needs to be overridden to ignore force field holes.
namespace IslandContextualMoves
{
	// This is a copy of Targetable::RequireNotOccludedFromCamera with some modifications to ignore holes in force fields
	bool ForceFieldRequirePlayerCanReachTargetable(FTargetableQuery& Query, float TracePullback = 100.0, bool bIgnoreOwnerCollision = true)
	{
		// If we are already invisible and cannot be the primary target, we don't need to trace
		if (!Query.Result.bVisible)
		{
			if (Query.Result.Score <= 0.0 || !Query.IsCurrentScoreViableForPrimary())
				return false;
			if (!Query.Result.bPossibleTarget)
				return false;
		}

		Query.bHasPerformedTrace = true;

		FIslandHazeTraceSettings Trace = IslandTrace::InitFromPlayer(Query.Player);
		Trace.IgnorePlayers();
		Trace.IgnoreCameraHiddenComponents(Query.Player);

		if (bIgnoreOwnerCollision)
			Trace.IgnoreActor(Query.Component.Owner);

		FVector TargetPosition = Query.TargetableLocation;
		if (TracePullback != 0.0)
			TargetPosition -= (TargetPosition - Query.Player.ActorLocation).GetSafeNormal() * TracePullback;

		FHitResult Hit = Trace.QueryTraceSingle(
			Query.Player.ActorLocation,
			TargetPosition,
		);

		if(Hit.bBlockingHit && Hit.Actor.IsA(AIslandRedBlueForceField))
		{
			Query.Result.bPossibleTarget = false;
			return true;
		}

		if (Hit.bBlockingHit)
		{
			Query.Result.Score = 0.0;
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
			return false;
		}
		else
		{
			return true;
		}
	}
}