
UCLASS(Abstract)
class UWorld_Tundra_EvergreenSide_Barrel_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnReceiveMonkey(){}

	UFUNCTION(BlueprintEvent)
	void OnShootMonkey(){}

	UFUNCTION(BlueprintEvent)
	void OnStopTurning(){}

	UFUNCTION(BlueprintEvent)
	void OnStartTurning(){}

	/* END OF AUTO-GENERATED CODE */

	float PreviousPitch = 0;
	float RotationVelocity = 0;
	AEvergreenBarrel Barrel;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Barrel = Cast<AEvergreenBarrel>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousPitch = 0;
		RotationVelocity = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		auto NewPitch = HazeOwner.ActorRotation.Pitch;
		RotationVelocity = Math::Abs( (PreviousPitch - NewPitch)/DeltaSeconds) / Barrel.RotationSpeedInDegrees;
		PreviousPitch = NewPitch;
	}

	UFUNCTION(BlueprintPure)
	float GetPitchVelocity() const
	{
		return RotationVelocity;
	}
}