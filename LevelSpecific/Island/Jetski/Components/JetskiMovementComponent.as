UCLASS(HideCategories = "ComponentTick Debug Activation Cooking Disable Tags Collision")
class UJetskiMovementComponent : UHazeMovementComponent
{
	default bConstrainRotationToHorizontalPlane = false;
	default bCanRerunMovement = true;
	default bAllowSnappingPostSequence = true;

	private AJetski Jetski;

	UJetskiMovementSettings MovementSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		Jetski = Cast<AJetski>(Owner);

		MovementSettings = UJetskiMovementSettings::GetSettings(Jetski);
		
		UMovementGravitySettings::SetGravityScale(Jetski, MovementSettings.GravityScale, this, EHazeSettingsPriority::Defaults);
		UMovementStandardSettings::SetWalkableSlopeAngle(Jetski, 70, this, EHazeSettingsPriority::Defaults);
		UMovementStandardSettings::SetAlsoUseActorUpForWalkableSlopeAngle(Jetski, true, this);
	}

	void PostSequencerControl(FHazePostSequencerControlParams Params) override
	{
		if(Params.bSmoothSnapToGround)
		{
			SnapToWaveHeight();
		}
	}

	void SnapToWaveHeight()
	{
#if !RELEASE
		GetTemporalLog().Event("SnapToWaveHeight");
		const FTemporalLog TemporalLog = GetTemporalLog().Section("SnapToWaveHeight");
		LogMovementShapeAtLocation(TemporalLog, "Before Snap", Owner.ActorLocation, FLinearColor::Red);
#endif

		// Snap to water instead
		const float WaveHeight = Jetski.GetWaveHeight();
		FVector TargetLocation = Jetski.ActorLocation;
		TargetLocation.Z = WaveHeight + (Jetski.GetSphereRadius() - 10);
		SnapToLocationWithVerticalLerp(TargetLocation, 0.1);

#if !RELEASE
		LogMovementShapeAtLocation(TemporalLog, "After Snap", Owner.ActorLocation, FLinearColor::Green);
#endif
	}

	UJetskiMovementData SetupJetskiMovementData()
	{
		return Cast<UJetskiMovementData>(SetupMovementData(UJetskiMovementData));
	}
};