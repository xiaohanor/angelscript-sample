struct FSketchbookSelectableOnStartFillingUpEventData
{
	UPROPERTY(BlueprintReadOnly)
	bool bIsMio;
}

struct FSketchbookSelectableOnStopFillingUpEventData
{
	UPROPERTY(BlueprintReadOnly)
	bool bIsMio;

	UPROPERTY(BlueprintReadOnly)
	bool bFinished;
}

struct FSketchbookSelectableOnStartDrainingDownEventData
{
	UPROPERTY(BlueprintReadOnly)
	bool bIsMio;
}

struct FSketchbookSelectableOnStopDrainingDownEventData
{
	UPROPERTY(BlueprintReadOnly)
	bool bIsMio;

	UPROPERTY(BlueprintReadOnly)
	bool bFinished;
}

UCLASS(Abstract)
class USketchbookSelectableEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ASketchbookSelectable Selectable;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Selectable = Cast<ASketchbookSelectable>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFillingUp(FSketchbookSelectableOnStartFillingUpEventData EventData) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopFillingUp(FSketchbookSelectableOnStopFillingUpEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDrainingDown(FSketchbookSelectableOnStartDrainingDownEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopDrainingDown(FSketchbookSelectableOnStopDrainingDownEventData EventData) {}
};