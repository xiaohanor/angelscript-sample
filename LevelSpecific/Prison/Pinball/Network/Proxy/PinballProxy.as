UCLASS(Abstract)
class APinballProxy : AHazeActor
{
	AHazeActor RepresentedActor;

	// Initial
	float InitialGameTime;

	// Tick
	uint SubframeNumber = 0;
	float TickGameTime;
	float DeltaTime;

	// Final
	FPinballPredictedPath PredictedPath;

#if !RELEASE
	FTemporalLog GetInitialLog() const
	{
		return TEMPORAL_LOG(this).Page("Initial");
	}

	FTemporalLog GetSubframeLog() const
	{
		return TEMPORAL_LOG(this).Page(f"Subframe {SubframeNumber}");
	}
#endif
};