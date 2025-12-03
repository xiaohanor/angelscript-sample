UCLASS(Abstract)
class UDroneDoubleInteractEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	ADroneDoubleInteract DoubleInteract;

	UPROPERTY()
	float LidAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DoubleInteract = Cast<ADroneDoubleInteract>(Owner);
		LidAlpha = DoubleInteract.LidAlpha;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Event(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagnetDroneAttachEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMagnetDroneDetachedEvent(){}
};