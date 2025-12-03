class UGravityBikeSplineAlongSplineTriggerComponent : UAlongSplineComponent
{
	access Internal = private, UGravityBikeSplineAlongSplineTriggerCapability;

	access:Internal
	bool bActivated = false;

	/**
	 * If false, we actually need to pass this trigger for it to activate
	 */
	UPROPERTY(EditInstanceOnly, Category = "Along Spline Trigger")
	bool bActivateOnSplineChangedEvenWhenPassed = true;

	access:Internal
	void ActivateTrigger() final
	{
		if(bActivated)
			return;

		bActivated = true;

		OnActivated();
	}

	protected void OnActivated()
	{
	}
};

#if EDITOR
class UGravityBikeSplineAlongSplineTriggerComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineAlongSplineTriggerComponent;

	UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto TriggerComp = Cast<UGravityBikeSplineActivateEnemiesTriggerComponent>(Component);
		if(TriggerComp == nullptr)
			return;

		DrawWireBox(
			TriggerComp.WorldLocation,
			FVector(0, 2000, 1000),
			TriggerComp.ComponentQuat,
			TriggerComp.EditorColor,
			3,
			true
		);
	}
}
#endif