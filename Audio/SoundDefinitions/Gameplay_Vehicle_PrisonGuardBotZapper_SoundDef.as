
UCLASS(Abstract)
class UGameplay_Vehicle_PrisonGuardBotZapper_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnShoot(FPrisonGuardBotShootParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnZapStop(FPrisonGuardBotZapParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnZapStart(FPrisonGuardBotZapParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnExplode(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnChargeStart(){}

	UFUNCTION(BlueprintEvent)
	void OnTelegraphCharge(){}

	UFUNCTION(BlueprintEvent)
	void OnMagneticBurstStunnedEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnMagneticBurstStunnedStart(){}

	/* END OF AUTO-GENERATED CODE */

	const float MAX_ELEVATION_DELTA_RANGE = 40;
	float LastElevationPos = 0;

	URemoteHackingResponseComponent HackingResponseComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HackingResponseComp = URemoteHackingResponseComponent::Get(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HackingResponseComp.bHacked)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HackingResponseComp.bHacked)
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	float GetElevationDeltaNormalized()
	{
		const float CurrElevation = DefaultEmitter.GetAudioComponent().GetWorldLocation().Z;
		const float ElevationDelta = CurrElevation - LastElevationPos;

		const float DeltaSign = Math::Sign(ElevationDelta);

		float ElevationDeltaNormalized = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_ELEVATION_DELTA_RANGE), FVector2D(0.0, 1.0), Math::Abs(ElevationDelta));
		ElevationDeltaNormalized *= DeltaSign;

		LastElevationPos = CurrElevation;
		return ElevationDeltaNormalized;
	}

}