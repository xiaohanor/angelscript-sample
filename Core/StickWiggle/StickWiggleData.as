
delegate void FOnStickWiggleCompleted();
delegate void FOnStickWiggleCanceled();

namespace StickWiggle
{

// Console variables to turn all button mashes into directions instead
const FConsoleVariable CVar_RemoveStickWiggle_Mio("Haze.RemoveStickWiggle_Mio", 0);
const FConsoleVariable CVar_RemoveStickWiggle_Zoe("Haze.RemoveStickWiggle_Zoe", 0);

// When we're not doing a spin, but a directional hold, pretend we're spinning this much per second
//const float RemovedSpinSpeed = 3.0;

};

struct FStickWiggleSettings
{
	// Allow the player to cancel spinning
	UPROPERTY(Category = "Gameplay")
	bool bAllowPlayerCancel = true;

	// Whether to block all other gameplay on the player while spinning
	UPROPERTY(Category = "Gameplay")
	bool bBlockOtherGameplay = true;

	// Whether to increase the progress in chunks or a smooth lerp
	UPROPERTY(Category = "Gameplay")
	bool bChunkProgress = false;

	//Used only if bChunkProgress is true
	UPROPERTY(Category = "Gameplay")
	int WigglesRequired = 10;

	//How far horizontally the stick must be held for the wiggle to register (a smaller number means vertical input will usually be counted)
	UPROPERTY(Category = "Gameplay")
	float HorizontalWiggleThreshold = 0.1;

	// Whether to display the default stick spin widget or not
	UPROPERTY(Category = "Stick Spin Widget")
	bool bShowStickSpinWidget = true;

	UPROPERTY(Category = "Stick Spin Widget", Meta = (EditCondition = "bShowStickSpinWidget", EditConditionHides))
	bool bShowProgressBar = true;

	// Which component to attach the widget to
	UPROPERTY(Category = "Stick Spin Widget", Meta = (EditCondition = "bShowStickSpinWidget", EditConditionHides))
	USceneComponent WidgetAttachComponent;

	// Position offset for the widget from its attachment. If no attachment, world position.
	UPROPERTY(Category = "Stick Spin Widget", Meta = (EditCondition = "bShowStickSpinWidget", EditConditionHides))
	FVector WidgetPositionOffset;

	// How long it should take for the wiggling intensity to go from 0 to 1.
	UPROPERTY(Category = "Stick Spin Widget")
	float WiggleIntensityIncreaseTime = 2;

	// If we haven't wiggled for this long, start decreasing
	UPROPERTY(Category = "Stick Spin Widget")
	float WiggleStartDecreasingDelay = 0.3;

	// How long it should take for the wiggling intensity to drop from 1 to 0.
	UPROPERTY(Category = "Stick Spin Widget")
	float WiggleIntensityDecreaseTime = 3;
};

struct FStickWiggleState
{
	UPROPERTY(Category = "Stick Spin")
	int WiggleInput;

	UPROPERTY(Category = "Stick Spin")
	float WiggledAlpha = 0.0;

	bool IsFinished() const
	{
		return WiggledAlpha > (1.0 - KINDA_SMALL_NUMBER);
	}
};