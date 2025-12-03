/**
 * Used by capabilities that find targets to attract to
 */
UCLASS(Abstract)
class UMagnetDroneAttractAimComponent : UActorComponent
{
#if RELEASE
	default PrimaryComponentTick.bStartWithTickEnabled = false;
#else
	default PrimaryComponentTick.bStartWithTickEnabled = true;
#endif

	private UPlayerAimingComponent AimComp;

	FMagnetDroneTargetData AimData;
	float AimVisualProgress = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AimComp = UPlayerAimingComponent::Get(Owner);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneAttractAim");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this).Section("Aim Data");
		AimData.LogToTemporalLog(TemporalLog);
#endif
	}

	UFUNCTION(BlueprintPure)
	bool HasValidAimTarget() const
	{
		return AimData.IsValidTarget();
	}

	FAimingResult PerformAutoAiming() const
	{
		if(!AimComp.IsAiming(this))
			return FAimingResult();

		return AimComp.GetAimingTarget(this);
	}

	void GetTraceLocations(FVector& TraceStart, FVector& TraceEnd, float TraceDistance = 1.0) const
	{
		const FAimingRay AimingRay = AimComp.GetPlayerAimingRay();
		const FVector TraceDelta = (AimingRay.Direction * TraceDistance);

		TraceStart = Math::RayPlaneIntersection(
			AimingRay.Origin,
			AimingRay.Direction,
			// we offset it to fix collision bugs with the camera when 
			// attached to a surface that is slightly tilted down 
			FPlane(Owner.ActorLocation, (AimingRay.Direction.VectorPlaneProject(FVector::UpVector).GetSafeNormal()))
		);

		TraceEnd = TraceStart + TraceDelta;
	}

};