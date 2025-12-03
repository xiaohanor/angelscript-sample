// for 2D plane which the players "move" on
asset SanctuaryBossMedallionFlyingPlaneSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USanctuaryBossMedallion2DPlaneMovementCapability);
	//Capabilities.Add(USanctuaryBossMedallion2DPlaneSizeCapability);
	Capabilities.Add(USanctuaryBossMedallion2DPlaneEventCapability);
	Capabilities.Add(USanctuaryBossMedallion2DPlaneLoopPhaseCapability);

	Capabilities.Add(UMedallionRespawnUnblockCapability); // might as well be here :shrug:
}

class ASanctuaryBossMedallion2DPlane : AHazeActor
{
	access AccessCapability = private, 
		USanctuaryBossMedallion2DPlaneMovementCapability, 
		USanctuaryBossMedallion2DPlaneEventCapability,
		USanctuaryBossMedallion2DPlaneLoopPhaseCapability,

		UMedallionPlayerFlyingCheckHydrasCapability,
		UMedallionPlayerGloryKill0SelectHydraCapability,
		UMedallionPlayerFlyingKnockedCapability,

		ASanctuaryBossMedallionHydraTransformActor;

	access : AccessCapability FHazeAcceleratedFloat AccSplineDistance;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(SanctuaryBossMedallionFlyingPlaneSheet);

	// -----------------------

	FSanctuaryMedallionSplineEvent OnSplineEvent;

	const float PlaneWidth = 6500.0; // 7500;//
	const float PlaneHeight = 2500.0;
	FVector2D PlaneExtents = FVector2D(PlaneWidth, PlaneHeight) * 0.5;

	ASanctuaryBossMedallionHydraReferences Refs;

	bool bDevInstantFly = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	float GetPlaneHeightRatio() const
	{
		return PlaneExtents.Y / PlaneExtents.X;
	}

	FVector ProjectOnPlane(FVector Location)
	{
		FVector Relative = Location - ActorLocation;
		float ProjectionDist = ActorForwardVector.DotProduct(Relative);
		return Location + Relative * ProjectionDist;
	}

	FRotator GetPlayerHeadingRotation()
	{
		return ActorRotation;
	}

	FVector GetDirectionInWorld(FVector2D DirectionOnPlane)
	{
		return (ActorUpVector * DirectionOnPlane.Y) + (ActorRightVector * DirectionOnPlane.X);
	}

	FVector GetLocationInWorld(FVector2D LocationOnPlane)
	{
		return ActorLocation + (ActorUpVector * LocationOnPlane.Y) + (ActorRightVector * LocationOnPlane.X);
	}

	FVector2D GetLocationOnPlane(FVector WorldLocationOnPlane)
	{
		FVector RelativeLocation = WorldLocationOnPlane - ActorLocation;
		float Forwards = ActorRightVector.DotProduct(RelativeLocation);
		float Upwards = ActorUpVector.DotProduct(RelativeLocation);
		return FVector2D(Forwards, Upwards);
	}

	FVector2D GetDirectionOnPlane(FVector WorldDirectionOnPlane)
	{
		float Forwards = ActorRightVector.DotProduct(WorldDirectionOnPlane);
		float Upwards = ActorUpVector.DotProduct(WorldDirectionOnPlane);
		return FVector2D(Forwards, Upwards);
	}

	FVector GetLocationSnappedToPlane(FVector WorldLocationOnPlane)
	{
		FVector RelativeLocation = WorldLocationOnPlane - ActorLocation;
		float Forwards = ActorRightVector.DotProduct(RelativeLocation);
		float Upwards = ActorUpVector.DotProduct(RelativeLocation);
		return ActorLocation + (ActorRightVector * Forwards) + (ActorUpVector * Upwards);
	}

	bool IsOutsideOfPlaneX(FVector2D RelativeLocation)
	{
		float LargerPlane = PlaneExtents.X * 1.2;
		if (RelativeLocation.X < -LargerPlane)
			return true;
		if (RelativeLocation.X > LargerPlane)
			return true;
		return false;
	}

	bool IsOutsideOfPlaneY(FVector2D RelativeLocation)
	{
		float LargerPlane = PlaneExtents.Y * 1.2;
		if (RelativeLocation.Y < -LargerPlane)
			return true;
		if (RelativeLocation.Y > LargerPlane)
			return true;
		return false;
	}

	access : AccessCapability ASanctuaryBossMedallionSpline GetFlyingSpline()
	{
		if (Refs == nullptr)
		{
			TListedActors<ASanctuaryBossMedallionHydraReferences> LevelRefs;
			Refs = LevelRefs.Single;
		}
		return Refs.FlyingPhasesDatas[Refs.HydraAttackManager.GetFlyingPhase()].FlyingSpline;
	}

	UFUNCTION(BlueprintCallable)
	void SetupBeforeStrangle()
	{
		bDevInstantFly = true;
		ASanctuaryBossMedallionSpline FlyingSpline = GetFlyingSpline();
		AccSplineDistance.SnapTo(FlyingSpline.Spline.SplineLength * 0.1);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this, "Plane").Value("SplineDist", AccSplineDistance.Value);
		const ASanctuaryBossMedallionSpline FlyingSpline = GetFlyingSpline();
		TEMPORAL_LOG(this, "Plane").Value("Spline", FlyingSpline);
		TEMPORAL_LOG(this, "Plane").Value("FlyingPhase", Refs.HydraAttackManager.GetFlyingPhase());
#endif
	}
};