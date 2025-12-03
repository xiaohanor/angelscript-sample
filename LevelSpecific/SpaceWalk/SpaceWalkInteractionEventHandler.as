struct FSpaceWalkInteractionEventHandlerData
{
	FSpaceWalkInteractionEventHandlerData(AHazePlayerCharacter _Player)
	{
		Player = _Player;
	}

	UPROPERTY()
	AHazePlayerCharacter Player;

}

struct FSpaceWalkInteractionEventHandlerDataProgress
{
	FSpaceWalkInteractionEventHandlerDataProgress(int _Progress)
	{
		Progress = _Progress;
	}

	UPROPERTY()
	int Progress;

}

struct FSpaceWalkInteractionEventHandlerDataProgressOxygen
{
	FSpaceWalkInteractionEventHandlerDataProgressOxygen(int _ProgressOxygen)
	{
		ProgressOxygen = _ProgressOxygen;
	}

	UPROPERTY()
	int ProgressOxygen;

}

UCLASS(Abstract)
class USpaceWalkInteractionEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Start(FSpaceWalkInteractionEventHandlerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SwipeLeft(FSpaceWalkInteractionEventHandlerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SwipeRight(FSpaceWalkInteractionEventHandlerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Press(FSpaceWalkInteractionEventHandlerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UIMoveIn(FSpaceWalkInteractionEventHandlerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UIMoveOut(FSpaceWalkInteractionEventHandlerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UISuccess() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UIFail() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Progress(FSpaceWalkInteractionEventHandlerDataProgress ProgressData) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ProgressOxygen(FSpaceWalkInteractionEventHandlerDataProgress ProgressDataOxygen) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Scramble() {}
};