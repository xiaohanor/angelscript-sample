enum ESkylineBossHatchState
{
	Closed,
	Opening,
	Open,
	Closing,
};

UCLASS(NotBlueprintable, HideCategories = "Debug ComponentTick Activation Cooking Disable Tags Navigation")
class USkylineBossHatchComponent : UActorComponent
{
	private ASkylineBoss Boss;
	private ESkylineBossHatchState State = ESkylineBossHatchState::Closed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASkylineBoss>(Owner);

		Boss.LeftHalfPipeTrigger.DisableTrigger(this);
		Boss.RightHalfPipeTrigger.DisableTrigger(this);
	}

	void OpenHatch()
	{
		State = ESkylineBossHatchState::Opening;

		PrintToScreen("OpenHatch!", 5.0, FLinearColor::Green);
		USkylineBossEventHandler::Trigger_OpenHatch(Boss);
	}

	void OnOpened()
	{
		State = ESkylineBossHatchState::Open;

		Boss.LeftHalfPipeTrigger.EnableTrigger(this);
		Boss.RightHalfPipeTrigger.EnableTrigger(this);
	}

	void CloseHatch()
	{
		State = ESkylineBossHatchState::Closing;

		USkylineBossEventHandler::Trigger_CloseHatch(Boss);

		Boss.LeftHalfPipeTrigger.DisableTrigger(this);
		Boss.RightHalfPipeTrigger.DisableTrigger(this);
	}

	const ESkylineBossHatchState GetState() const
	{
		return State;
	}

	void OnClosed()
	{
		State = ESkylineBossHatchState::Closed;
	}

	bool IsHatchOpen() const
	{
		return State == ESkylineBossHatchState::Open;
	}
};