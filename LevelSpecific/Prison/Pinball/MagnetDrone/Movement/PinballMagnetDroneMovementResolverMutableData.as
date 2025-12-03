class UPinballMagnetDroneMovementResolverMutableData : UMovementResolverMutableData
{
#if EDITOR
	TArray<FMovementHitResult> DebugMovementSweeps;
#endif
	
	void OnPrepareResolver() override
	{
		Super::OnPrepareResolver();

#if EDITOR
		DebugMovementSweeps.Reset();
#endif
	}
}