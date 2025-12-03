const FStatID STAT_PinballPredictability_ProcessPredictabilityTick(n"PinballPredictability_ProcessPredictabilityTick");
const FStatID STAT_PinballPredictability_InitPredictabilityState(n"PinballPredictability_InitPredictabilityState");

/**
 * Base class for Predictabilities.
 * Basically Capabilities, but they run on APinballProxy, and tick multiple times per frame.
 */
UCLASS(Abstract)
class UPinballPredictability
{
	access Internal = private, UPinballPredictabilitySystemComponent;

	EHazeTickGroup TickGroup = EHazeTickGroup::Gameplay;
	int TickGroupOrder = 100;

	private APinballProxy Owner;
	protected bool bIsActive = false;

	// float ActiveDuration = 0;
	// float DeactiveDuration = 0;

	/**
	 * Called after updating components to match the control state.
	 * Internally triggers deactivation and activation.
	 */
	void InitPredictabilityState()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictability_InitPredictabilityState);

		if(ShouldActivate(true))
		{
			Activate(true);
		}
		else
		{
			// Predictabilities are disabled by default
			bIsActive = false;
		}
	}

	access:Internal
	void ProcessPredictabilityTick(float DeltaTime) final
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictability_ProcessPredictabilityTick);

		PreTick(DeltaTime);

		if(bIsActive)
		{
			if(ShouldDeactivate())
				Deactivate();
		}
		else
		{
			if(ShouldActivate(false))
				Activate(false);
		}

#if !RELEASE
		FTemporalLog SubframeLog = GetSubframeLog();
		LogState(SubframeLog);
#endif

		if(bIsActive)
		{
#if !RELEASE
			LogActive(SubframeLog);
#endif

			TickActive(DeltaTime);
			// ActiveDuration += DeltaTime;
		}
		else
		{
			//DeactiveDuration += DeltaTime;
		}
	}

	void Setup(APinballProxy InProxy)
	{
		Owner = InProxy;
	}

	private void Activate(bool bInit) final
	{
		bIsActive = true;
		OnActivated(bInit);
		//DeactiveDuration = 0.0;
	}

	private void Deactivate() final
	{
		bIsActive = false;
		OnDeactivated();
		// ActiveDuration = 0.0;
	}

	/**
	 * Should this predictability be active?
	 * @param bInit If true, this is called while preparing the prediction. If you return true here, the the predictability was active from the start, and not activated during the prediction
	 */
	bool ShouldActivate(bool bInit)
	{
		return true;
	}

	bool ShouldDeactivate()
	{
		return false;
	}

#if !RELEASE
	void LogState(FTemporalLog SubframeLog) const
	{
		if(bIsActive)
			SubframeLog.Status(f"Activated", FLinearColor::Green);
		else
			SubframeLog.Status(f"Deactivated", FLinearColor::Red);
	}
#endif

#if !RELEASE
	void LogActive(FTemporalLog SubframeLog) const
	{
	}
#endif

	void OnActivated(bool bInit)
	{

	}

	void OnDeactivated()
	{

	}

	void PreTick(float DeltaTime)
	{

	}

	void TickActive(float DeltaTime)
	{

	}

	/**
	 * Handles clearing any state that may not be kept into the next frame.
	 * Any state that is not reset from the synced data should be considered to handle here.
	 * For example, Deactivate will not be automatically called at the end of prediction, instead
	 * you are expected to handle any clean up here.
	 */
	void PostPrediction()
	{

	}

	int opCmp(UPinballPredictability Other) const final
	{
		return TickGroupOrder > Other.TickGroupOrder ? 1 : -1;
	}

#if !RELEASE
	FTemporalLog GetSubframeLog() const final
	{
		return Owner.GetSubframeLog().Page("Predictabilities").Page(Name.ToString());
	}
#endif
}