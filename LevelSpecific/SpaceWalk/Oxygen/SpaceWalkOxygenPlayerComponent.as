class USpaceWalkOxygenPlayerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<USpaceWalkOxygenWidget> WidgetClass;
	UPROPERTY()
	TSubclassOf<USpaceWalkOxygenInteractionTimingWidget> TimingWidgetClass;
	UPROPERTY()
	TPerPlayer<UAnimSequence> OxygenDeathFloating;
	UPROPERTY()
	TPerPlayer<UAnimSequence> OxygenDeathTouchScreen;

	float OxygenLevel = 1.0;
	bool bHasRunOutOfOxygen = false;
	ASpaceWalkOxygenInteraction OxygenInteraction;

	TInstigated<float> OxygenDepletionRate(1.0);

	bool bTouchScreenGrounded = false;
	FFrameBool AnimTouchScreenStepLeft;
	FFrameBool AnimTouchScreenStepRight;
	FFrameBool AnimTouchScreenConfirm;
};

struct FFrameBool
{
	uint32 LastSetFrame = 0;
	bool bEverSet = false;

	void Set()
	{
		LastSetFrame = GFrameNumber;
		bEverSet = true;
	}

	bool IsSetThisFrame()
	{
		return bEverSet && LastSetFrame == GFrameNumber;
	}
}