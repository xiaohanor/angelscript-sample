
UCLASS(Abstract)
class ULightBeamEventHandler : UHazeEffectEventHandler
{

	ULightBeamUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightBeamUserComponent::Get(Owner);
	}

	// Called when the light beam starts firing.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFiring() { }

	// Called when the light beam stops firing.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFiring() { }

	// Called when the light beam hits a new target.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHit(FLightBeamHitData HitData) { }

	// Called when the light beam stops hitting a target.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EndHit(FLightBeamHitData HitData) { }

	// Whether the light beam is currently being fired.
	UFUNCTION(BlueprintPure)
	bool IsFiring() const
	{
		return UserComp.bIsFiring;
	}

	// Returns the start location of the light beam.
	UFUNCTION(BlueprintPure)
	FVector GetStartLocation() const
	{
		return UserComp.StartLocation;
	}

	// Returns the end location of the light beam.
	UFUNCTION(BlueprintPure)
	FVector GetEndLocation() const
	{
		return UserComp.EndLocation;
	}

	// Returns the trace radius of the light beam.
	UFUNCTION(BlueprintPure)
	float GetTraceRadius() const
	{
		return LightBeam::BeamRadius;
	}
}