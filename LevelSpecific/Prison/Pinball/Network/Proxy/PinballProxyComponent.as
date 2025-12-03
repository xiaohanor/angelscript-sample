/**
 * Base class for components used in the Predictability system
 */
UCLASS(Abstract)
class UPinballProxyComponent : UActorComponent
{
	access System = private, UPinballPredictabilitySystemComponent;

	// The component the PredictabilityComponent is a copy of
	TSubclassOf<UActorComponent> ControlComponentClass;

	private APinballProxy BaseProxy;
	
	access:System const UActorComponent ControlComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BaseProxy = Cast<APinballProxy>(Owner);

		ControlComponent = BaseProxy.RepresentedActor.GetComponentByClass(ControlComponentClass);
		check(ControlComponent != nullptr, f"Could not find ControlComponent of class {ControlComponentClass} for ProxyComponent {this}");
	}

	/**
	 * Initialize this component at the start of prediction to be the same state as the control version of this component
	 */
	void InitComponentState(const UActorComponent ControlComp)
	{
	}

#if !RELEASE
	void LogComponentState(FTemporalLog TemporalLog) const
	{
	}
#endif
};