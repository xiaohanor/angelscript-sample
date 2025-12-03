namespace Perception
{
	bool VisibilityExists(AHazeActor FromActor, AHazeActor ToActor, FVector FromOffset = FVector::ZeroVector, FVector ToOffset = FVector::ZeroVector)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Trace.UseLine();
		Trace.IgnoreActor(FromActor);
		Trace.IgnoreActor(ToActor);

		FHitResult Obstruction = Trace.QueryTraceSingle(FromActor.FocusLocation + FromOffset, ToActor.FocusLocation + ToOffset);
		return !Obstruction.bBlockingHit;
	}
}