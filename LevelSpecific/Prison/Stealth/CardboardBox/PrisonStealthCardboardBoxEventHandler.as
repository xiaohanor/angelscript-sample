UCLASS(Abstract)
class UPrisonStealthCardboardBoxEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APrisonStealthCardboardBox CardboardBox;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CardboardBox = Cast<APrisonStealthCardboardBox>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCardboardBoxEnter() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCardboardBoxLeave() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCardboardHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCardboardDisappear() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCardboardRespawn() {}
};