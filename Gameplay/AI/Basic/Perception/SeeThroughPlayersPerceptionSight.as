class USeeThroughPlayersPerceptionSight : UBasicAIPerceptionSight
{
	bool VisibilityExists(AHazeActor Owner, AHazeActor Target, FVector OwnerOffset = FVector::ZeroVector, FVector TargetOffset = FVector::ZeroVector, ECollisionChannel CollisionChannel = ECollisionChannel::ECC_Visibility) override
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		if(CollisionChannel != ECollisionChannel::ECC_Visibility)
			Trace = Trace::InitChannel(CollisionChannel);
		Trace.UseLine();
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(Target);

		// Players should never block visibility (or you can hide within each other :P)
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);

		FHitResult Obstruction = Trace.QueryTraceSingle(Owner.FocusLocation + OwnerOffset, Target.FocusLocation + TargetOffset);
		return !Obstruction.bBlockingHit;
	}
}