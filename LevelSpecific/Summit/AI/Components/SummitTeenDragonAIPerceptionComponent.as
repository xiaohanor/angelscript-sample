class USummitTeenDragonAIPerceptionSight : UBasicAIPerceptionSight
{
	bool VisibilityExists(AHazeActor Owner, AHazeActor Target, FVector OwnerOffset = FVector::ZeroVector, FVector TargetOffset = FVector::ZeroVector, ECollisionChannel CollisionChannel = ECollisionChannel::ECC_Visibility) override
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		if(CollisionChannel != ECollisionChannel::ECC_Visibility)
			Trace = Trace::InitChannel(CollisionChannel);
		Trace.UseLine();
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(Target);

		ATeenDragon TeenDragon = Cast<ATeenDragon>(Target);
		if(TeenDragon != nullptr)
			Trace.IgnoreActor(TeenDragon);

		UPlayerTeenDragonComponent TeenDragonComp = UPlayerTeenDragonComponent::Get(Target);
		if(TeenDragonComp != nullptr)
			Trace.IgnoreActor(Target);

		FHitResult Obstruction = Trace.QueryTraceSingle(Owner.FocusLocation + OwnerOffset, Target.FocusLocation + TargetOffset);
		return !Obstruction.bBlockingHit;
	}
}