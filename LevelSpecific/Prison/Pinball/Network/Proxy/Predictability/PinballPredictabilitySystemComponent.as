const FStatID STAT_PinballPredictabilitySystemComponent_InitStateFromControl(n"PinballPredictabilitySystemComponent_InitStateFromControl");
const FStatID STAT_PinballPredictabilitySystemComponent_TickFromPrediction(n"PinballPredictabilitySystemComponent_TickFromPrediction");
const FStatID STAT_PinballPredictabilitySystemComponent_PostPrediction(n"PinballPredictabilitySystemComponent_PostPrediction");

struct FPinballPredictabilityTickGroup
{
	EHazeTickGroup TickGroup;
	TArray<UPinballPredictability> Predictabilities;

	FPinballPredictabilityTickGroup(EHazeTickGroup InTickGroup)
	{
		TickGroup = InTickGroup;
	}
}

class UPinballPredictabilitySystemComponent : UActorComponent
{
	TArray<TSubclassOf<UPinballPredictability>> PredictabilityClasses;

	// Proxy
	private APinballProxy Proxy;
	private TArray<UPinballProxyComponent> ProxyComponents;
	private TArray<FPinballPredictabilityTickGroup> PredictabilityTickGroups;

	// Player
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Proxy = Cast<APinballProxy>(Owner);

		Player = Pinball::GetBallPlayer();

		Proxy.GetComponentsByClass(ProxyComponents);

		for(int i = 0; i < int(EHazeTickGroup::MAX); i++)
			PredictabilityTickGroups.Add(FPinballPredictabilityTickGroup(EHazeTickGroup(i)));

		for(TSubclassOf<UPinballPredictability> PredictabilityClass : PredictabilityClasses)
		{
			UPinballPredictability Predictability = NewObject(this, PredictabilityClass);
			Predictability.Setup(Proxy);
			FPinballPredictabilityTickGroup& PredictabilityTickGroup = PredictabilityTickGroups[int(Predictability.TickGroup)];
			PredictabilityTickGroup.Predictabilities.Add(Predictability);
		}

		// Sort the predictabilities by their tick group order
		for(int i = PredictabilityTickGroups.Num() - 1; i >= 0; i--)
		{
			if(PredictabilityTickGroups[i].Predictabilities.IsEmpty())
			{
				PredictabilityTickGroups.RemoveAt(i);
				continue;
			}

			PredictabilityTickGroups[i].Predictabilities.Sort();
		}
	}

	void InitStateFromControl()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictabilitySystemComponent_InitStateFromControl);

		// Initialize all components from the control state
		for(UPinballProxyComponent ProxyComp : ProxyComponents)
		{
			ProxyComp.InitComponentState(ProxyComp.ControlComponent);
#if !RELEASE
			ProxyComp.LogComponentState(TEMPORAL_LOG(Proxy).Page("Initial").Page(ProxyComp.Name.ToString()));
#endif
		}

		// Initialize all predictabilities from the control state
		for(const FPinballPredictabilityTickGroup& Group : PredictabilityTickGroups)
		{
			for(UPinballPredictability Predictability : Group.Predictabilities)
			{
				Predictability.InitPredictabilityState();
			}
		}
	}

	void TickFromPrediction(float DeltaTime)
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictabilitySystemComponent_TickFromPrediction);

#if !RELEASE
		for(UPinballProxyComponent ProxyComp : ProxyComponents)
		{
			FTemporalLog SubframeLog = Proxy.GetSubframeLog().Page(ProxyComp.Name.ToString());
			ProxyComp.LogComponentState(SubframeLog);
		}
#endif

		for(FPinballPredictabilityTickGroup& Group : PredictabilityTickGroups)
		{
			for(UPinballPredictability Predictability : Group.Predictabilities)
			{
				Predictability.ProcessPredictabilityTick(DeltaTime);
			}
		}
	}

	void DispatchPostPrediction()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictabilitySystemComponent_PostPrediction);

		for(FPinballPredictabilityTickGroup& Group : PredictabilityTickGroups)
		{
			for(UPinballPredictability Predictability : Group.Predictabilities)
			{
				Predictability.PostPrediction();
			}
		}
	}
};