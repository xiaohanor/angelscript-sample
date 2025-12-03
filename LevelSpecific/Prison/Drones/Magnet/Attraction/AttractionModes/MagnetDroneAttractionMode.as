/**
 * Base class for Attraction Modes.
 * One instance of each child of this class will assigned on UMagnetDroneAttractionComponent will be created on BeginPlay.
 * 
 * The idea is that this will allow for a contained way of handling the math of
 * where we want to go during an attraction, while also allowing it to be simulated
 * ahead of time, since we need a path to be visible to the player when targeting.
 * 
 * Therefore, this class is not allowed to modify anything outside of it, only return values.
 */
UCLASS(Abstract, NotBlueprintable)
class UMagnetDroneAttractionMode
{
	access AttractionComp = private, UMagnetDroneAttractionComponent;
	access AttractionModeCapability = private, UMagnetDroneAttractionModesCapability, UPinballMagnetAttractionModesCapability, UMagnetDroneAttractionPreviewCapability, UPinballProxyMagnetAttractionModesPredictability;

	protected int TickOrder = 100;

	private const UMagnetDroneAttractionComponent AttractionComp;
	protected const UDroneMovementSettings MovementSettings;
	protected bool bAllowWhileAttached = false;

	private FMagnetDroneAttractionModePrepareAttractionParams PrepareParams;

	private FInstigator PrepareInstigator;
	private bool bPreparing = false;
	private bool bPrepared = false;

	private FTransform PreviousFrameTargetTransform;

#if !RELEASE
	FLinearColor DebugColor = FLinearColor::LucBlue;
	int DebugPreviewIteration = 0;
	FHazeRuntimeSpline DebugSpline;
#endif

	void Setup(FMagnetDroneAttractionModeSetupParams Params)
	{
		AttractionComp = UMagnetDroneAttractionComponent::Get(Params.Player);
		MovementSettings = UDroneMovementSettings::GetSettings(Params.Player);
	}

	bool ShouldActivate(FMagnetDroneAttractionModeShouldActivateParams Params) const
	{
		if(Params.bIsAttached && !bAllowWhileAttached)
			return false;

		return true;
	}

	access:AttractionModeCapability
	bool RunPrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutTimeUntilArrival, FInstigator Instigator) final
	{
		if(!ensure(!bPrepared))
			return false;

		PrepareInstigator = Instigator;
		PrepareParams = Params;

		PreviousFrameTargetTransform = Params.AttractionTarget.GetTargetComp().WorldTransform;
		
		bPreparing = true;

		float PathLength;
		if(!PrepareAttraction(Params, PathLength, OutTimeUntilArrival))
			return false;

		bPreparing = false;

		bPrepared = true;

#if !RELEASE
		DebugSpline.AddPoint(Params.InitialLocation);
#endif

		return true;
	}

	protected bool PrepareAttraction(FMagnetDroneAttractionModePrepareAttractionParams& Params, float&out OutPathLength, float&out OutTimeUntilArrival) no_discard
	{
		OutPathLength = CalculatePathLength();
		if(!ensure(OutPathLength >= KINDA_SMALL_NUMBER))
			return false;

		OutTimeUntilArrival = CalculateTimeUntilArrival(OutPathLength);
		if(!ensure(OutTimeUntilArrival >= KINDA_SMALL_NUMBER))
			return false;

		return true;
	}

	access:AttractionModeCapability
	FVector RunTickAttraction(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha) final
	{
		if(!ensure(bPrepared))
			return Params.CurrentLocation;

		FVector Location = TickAttraction(Params, DeltaTime, AttractionAlpha);

#if !RELEASE
		DebugSpline.AddPoint(Location);
#endif

		return Location;
	}

	private bool ShouldApplyTargetDeltaTransform() const
	{
		return PrepareParams.AttractionTarget.ShouldAttractRelative();
	}

	access:AttractionModeCapability
	void RunApplyTargetDeltaTransform()
	{
		if(!ShouldApplyTargetDeltaTransform())
			return;

		const FTransform CurrentTargetTransform = PrepareParams.AttractionTarget.GetTargetComp().WorldTransform;

		ApplyTargetDeltaTransform(PreviousFrameTargetTransform, CurrentTargetTransform);

		PreviousFrameTargetTransform = CurrentTargetTransform;
	}

	protected void ApplyTargetDeltaTransform(FTransform PreviousTargetTransform, FTransform CurrentTargetTransform)
	{
		check(ShouldApplyTargetDeltaTransform());
		PrepareParams.InitialLocation = CurrentTargetTransform.TransformPosition(PreviousTargetTransform.InverseTransformPosition(PrepareParams.InitialLocation));
		PrepareParams.InitialVelocity = CurrentTargetTransform.TransformVectorNoScale(PreviousTargetTransform.InverseTransformVectorNoScale(PrepareParams.InitialVelocity));
	}

	protected FVector TickAttraction(FMagnetDroneAttractionModeTickAttractionParams Params, float DeltaTime, float& AttractionAlpha)
	{
		check(false, "Implement in child classes!");
		return FVector::ZeroVector;
	}

	access:AttractionModeCapability
	void Reset()
	{
		bPrepared = false;

#if !RELEASE
		DebugPreviewIteration = -1;
		DebugSpline = FHazeRuntimeSpline();
#endif
	}

	float CalculatePathLength() const
	{
		float CurveLength = BezierCurve::GetLength_2CP(
			GetStartLocation(),
			GetStartLocation() + GetStartTangent(),
			GetEndLocation() + GetEndTangent(),
			GetEndLocation()
		);
		
		CurveLength = Math::Max(CurveLength, 10);
		return CurveLength;
	}

	float CalculateTimeUntilArrival(float PathLength) const
	{
		// this will decide when this capability is deactivate
		float Speed = MagnetDrone::AttractionSpeed;

		const FVector DirToEnd = (GetEndLocation() - InitialLocation).GetSafeNormal();
		const float SpeedInTargetDirection = InitialVelocity.DotProduct(DirToEnd);
		if(SpeedInTargetDirection > 0)
			Speed += InitialVelocity.DotProduct(DirToEnd);

		return PathLength / Speed;
	}

	protected const FMagnetDroneTargetData& GetAttractionTarget() const property final
	{
		check(bPrepared || bPreparing);
		return PrepareParams.AttractionTarget;
	}

	protected const FVector& GetInitialLocation() const property final
	{
		check(bPrepared || bPreparing);
		return PrepareParams.InitialLocation;
	}

	protected const FVector& GetInitialVelocity() const property final
	{
		check(bPrepared || bPreparing);
		return PrepareParams.InitialVelocity;
	}

	protected const FVector& GetInitialWorldUp() const property final
	{
		check(bPrepared || bPreparing);
		return PrepareParams.InitialWorldUp;
	}

	protected const FRotator& GetInitialViewRotation() const property final
	{
		check(bPrepared || bPreparing);
		return PrepareParams.InitialViewRotation;
	}

	FVector GetStartLocation() const
	{
		return InitialLocation;
	}

	FVector GetStartTangent() const
	{
		return InitialVelocity;
	}

	FVector GetEndTangent() const
	{
		return -AttractionTarget.GetTargetImpactNormal();
	}

	FVector GetEndLocation() const
	{
		return AttractionTarget.GetTargetLocation();
	}

#if !RELEASE
	void LogToTemporalLog(FTemporalLog SectionLog, FMagnetDroneAttractionModeLogParams Params) const
	{
		FTemporalLog StartSectionLog = SectionLog.Section("Start", -888);
		FTemporalLog EndSectionLog = SectionLog.Section("End", -777);
		FTemporalLog FinalSectionLog = SectionLog.Section("Final", -666);

		StartSectionLog.Point("Location", GetStartLocation(), Color = FLinearColor::Green);
		StartSectionLog.DirectionalArrow("Tangent", GetStartLocation(), GetStartTangent(), Color = FLinearColor::Green);

		EndSectionLog.Point(f"Location", GetEndLocation(), Color = FLinearColor::Red);
		EndSectionLog.DirectionalArrow("Tangent", GetEndLocation(), GetEndTangent(), Color = FLinearColor::Red);

		if(DebugSpline.Points.Num() >= 2)
		{
			FinalSectionLog.RuntimeSpline("Spline", DebugSpline);
			FinalSectionLog.Value("AttractionAlpha", Params.AttractionAlpha);
			FinalSectionLog.Value("ActiveDuration", Params.ActiveDuration);
		}
	}

	FTemporalLog GetTemporalLog(bool bSection = true) const
	{
		FString Section = Class.Name.PlainNameString;

		if(DebugPreviewIteration >= 0)
		{
			FTemporalLog TemporalLog = AttractionComp.GetTemporalLog().Page("Preview");

			if(!bSection)
				return TemporalLog;

			if(DebugPreviewIteration > 0)
				Section = f"{Section}_{DebugPreviewIteration}";

			return TemporalLog.Section(Section, DebugPreviewIteration, true);
		}
		else
		{
			FTemporalLog TemporalLog = AttractionComp.GetTemporalLog().Page("Attraction Mode");

			if(!bSection)
				return TemporalLog;

			return TemporalLog.Section(Section);
		}
	}
#endif

	int opCmp(UMagnetDroneAttractionMode Other) const final
	{
		if(TickOrder < Other.TickOrder)
			return -1;
		else
			return 1;
	}
}

#if !RELEASE
struct FMagnetDroneAttractionModeLogParams
{
	float AttractionAlpha;
	float ActiveDuration;

	FVector CurrentLocation;

	FMagnetDroneAttractionModeLogParams(float InAttractionAlpha, float InActiveDuration, FVector InCurrentLocation)
	{
		AttractionAlpha = InAttractionAlpha;
		ActiveDuration = InActiveDuration;
		CurrentLocation = InCurrentLocation;
	}
};
#endif