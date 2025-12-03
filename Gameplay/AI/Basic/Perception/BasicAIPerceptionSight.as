class UBasicAIPerceptionSight : UObject
{
	bool VisibilityExists(AHazeActor Owner, AHazeActor Target, FVector OwnerOffset = FVector::ZeroVector, FVector TargetOffset = FVector::ZeroVector, ECollisionChannel CollisionChannel = ECollisionChannel::ECC_Visibility)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		if(CollisionChannel != ECollisionChannel::ECC_Visibility)
			Trace = Trace::InitChannel(CollisionChannel);
		Trace.UseLine();
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(Target);

		// TODO Fix for next project:
		// We really should ignore players here as well since they block visibility nowadays and can stand on top of each other :P
		// Too late to fix globally so chosen AIs get the SeeThroughPlayersPerceptionSight instead.

		FHitResult Obstruction = Trace.QueryTraceSingle(Owner.FocusLocation + OwnerOffset, Target.FocusLocation + TargetOffset);
		return !Obstruction.bBlockingHit;
	}
}