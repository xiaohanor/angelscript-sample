UCLASS(Abstract)
class UCongaLineMonkeyEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ACongaLineMonkey Monkey;

	UPROPERTY(BlueprintReadOnly)
	UCongaLineDancerComponent DancerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ACongaLineMonkey>(Owner);
		DancerComp = UCongaLineDancerComponent::Get(Monkey);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartEntering()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEntered()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDisperse()
	{
	}
};