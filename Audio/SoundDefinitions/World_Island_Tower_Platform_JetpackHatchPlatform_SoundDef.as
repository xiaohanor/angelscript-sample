
UCLASS(Abstract)
class UWorld_Island_Tower_Platform_JetpackHatchPlatform_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Deactivate(){}

	UFUNCTION(BlueprintEvent)
	void Activate(){}

	UFUNCTION(BlueprintEvent)
	void StartShake(FIslandHatchPlatformShakeParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UHazeAudioActorMixer NodePropertyAmix;

	private UHazeAudioEmitter VentEmitter;

	float DistanceToClosestPlayer = 0;
	float32 VentsSoundDirection;
	float32 Azimuth;

	// Test to see how much this affects performance.

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		VentEmitter = Emitters.Last();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		UpdateAzimuthAndSoundDirection();
		UpdateDistance();
	}

	void UpdateDistance() 
	{
		auto NewDistanceToClosestPlayer = DefaultEmitter.GetAudioComponent().GetClosestPlayerDistance();

		if (Math::IsNearlyEqual(DistanceToClosestPlayer, NewDistanceToClosestPlayer))
		{
			return;
		}
		DistanceToClosestPlayer = NewDistanceToClosestPlayer;

		auto DistanceAlphaA = Math::GetMappedRangeValueClamped(
			FVector2D(1000, 2000),
				FVector2D(1, 0.25),
				DistanceToClosestPlayer
			);

		auto DistanceAlphaB = Math::GetMappedRangeValueClamped(
			FVector2D(1750, 2200),
				FVector2D(1.5, 1),
				DistanceToClosestPlayer
			);

		auto DistanceAlphaC = Math::GetMappedRangeValueClamped(
			FVector2D(3000, 12000),
				FVector2D(1, 0.5),
				DistanceToClosestPlayer
			);

		auto SoundDirectionAlpha = Math::GetMappedRangeValueClamped(
			FVector2D(.5, 1),
				FVector2D(DistanceAlphaA, 1),
				VentsSoundDirection
			);

		auto AzimuthAlpha = Math::GetMappedRangeValueClamped(
			FVector2D(0.75, .9),
				FVector2D(0.5, 1),
				Azimuth
			);

		auto DistanceResult = DistanceAlphaB * DistanceAlphaC * SoundDirectionAlpha;
		auto Result = AzimuthAlpha * DistanceResult;

		auto GainAmplitude = Audio::AmplitudeToDb(Result);

		SetNodePropertyAllEmitters(NodePropertyAmix, EHazeAudioNodeProperty::MakeUpGain, GainAmplitude);

		UpdateLFE();
	}

	void UpdateLFE()
	{
		auto DistanceAlphaA = Math::GetMappedRangeValueClamped(
			FVector2D(1500, 3000),
				FVector2D(0, 30),
				DistanceToClosestPlayer
			);

		auto SoundDirectionAlpha = Math::GetMappedRangeValueClamped(
			FVector2D(.5, 1),
				FVector2D(DistanceAlphaA, 0),
				VentsSoundDirection
			);

		auto DistanceAlphaB = Math::GetMappedRangeValueClamped(
			FVector2D(4000, 10000),
				FVector2D(0, 60),
				DistanceToClosestPlayer
			);

		auto AzimuthAlpha = Math::GetMappedRangeValueClamped(
			FVector2D(0.75, .9),
				FVector2D(15, 0),
				Azimuth
			);

		auto MaxResult = Math::Max3(SoundDirectionAlpha, DistanceAlphaB, AzimuthAlpha);

		SetNodePropertyAllEmitters(NodePropertyAmix, EHazeAudioNodeProperty::LFE, MaxResult);
	}

	void UpdateAzimuthAndSoundDirection()
	{
		Azimuth = DefaultEmitter.GetAudioComponent().GetAzimuth(false);
		VentsSoundDirection = GetSoundDirectionToListenersInRange(VentEmitter);
	}

}