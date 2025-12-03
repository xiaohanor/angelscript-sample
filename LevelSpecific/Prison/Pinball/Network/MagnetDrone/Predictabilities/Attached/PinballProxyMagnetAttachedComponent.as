UCLASS(NotBlueprintable, NotPlaceable)
class UPinballProxyMagnetAttachedComponent : UPinballMagnetDroneProxyComponent
{
	default ControlComponentClass = UMagnetDroneAttachedComponent;

	/**
	 * Synced data
	 * Initially the same as Control, but will be modified during the prediction
	 */
	FMagnetDroneAttachedData AttachedData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballProxyMagnetAttached");
#endif
	}

	void InitComponentState(const UActorComponent ControlComp) override
	{
		Super::InitComponentState(ControlComp);

#if !RELEASE
		FTemporalLog InitialLog = Proxy.GetInitialLog().Page(Name.ToString());
#endif

		AttachedData = Proxy.InitialSyncedData.AttachedData.AttachedData;
	}

#if !RELEASE
	void LogComponentState(FTemporalLog SubframeLog) const override
	{
		Super::LogComponentState(SubframeLog);
		
		// SubframeLog
		// 	.Value("Rail", Rail)
		// 	.Value("bIsInRail", bIsInRail)
		// 	.Value("Speed", Speed)
		// 	.Value("DistanceAlongSpline", DistanceAlongSpline)

		// 	.Value("EnterSide", EnterSide)
		// 	.Value("ExitSide", ExitSide)

		// 	.Value("EnterSyncPoint", EnterSyncPoint)
		// 	.Value("EnterSyncPointState", EnterSyncPointState)

		// 	.Value("ExitSyncPoint", ExitSyncPoint)
		// 	.Value("ExitSyncPointState", ExitSyncPointState)
		// ;

		// if(Rail != nullptr && Proxy.SubframeNumber == 0)
		// {
		// 	SubframeLog.RuntimeSpline("Rail Spline", Rail.Spline.BuildRuntimeSplineFromHazeSpline());
		// }
	}
#endif
	
	bool IsAttached() const
	{
		return AttachedData.CanAttach();
	}

	bool IsAttachedToSurface() const
	{
		if(!IsAttached())
			return false;

		return AttachedData.IsSurface();
	}

	bool AttachedThisFrame() const
	{
		return AttachedData.AttachedThisFrame();
	}
};