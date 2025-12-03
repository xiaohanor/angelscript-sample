
delegate void FOnStickSpinStateChanged(FStickSpinState State);
delegate void FOnStickSpinStopped();

namespace StickSpin
{

// Console variables to turn all button mashes into directions instead
const FConsoleVariable CVar_RemoveStickSpin_Mio("Haze.RemoveStickSpin_Mio", 0);
const FConsoleVariable CVar_RemoveStickSpin_Zoe("Haze.RemoveStickSpin_Zoe", 0);

// When we're not doing a spin, but a directional hold, pretend we're spinning this much per second
const float RemovedSpinSpeed = 3.0;

};

struct FStickSpinSettings
{
	// When both ways are allowed but counter clockwise is preferred / correct
	UPROPERTY(Category = "Stick Spin")
	bool bForceCounterClockwiseUI = false;

	// Whether the player is allowed to spin clockwise at all
	UPROPERTY(Category = "Stick Spin")
	bool bAllowSpinClockwise = true;
	
	// Whether the player is allowed to spin counter clockwise at all
	UPROPERTY(Category = "Stick Spin")
	bool bAllowSpinCounterClockwise = true;

	UPROPERTY(Category = "Stick Spin")
	bool bUseMinimumSpinPosition = false;

	// If turned on, prevent the player from spinning to a position lower than this
	UPROPERTY(Category = "Stick Spin")
	float MinimumSpinPosition = -10.0;

	UPROPERTY(Category = "Stick Spin")
	bool bUseMaximumSpinPosition = false;

	// If turned on, prevent the player from spinning to a position higher than this
	UPROPERTY(Category = "Stick Spin")
	float MaximumSpinPosition = 10.0;

	// Allow the player to cancel spinning
	UPROPERTY(Category = "Gameplay")
	bool bAllowPlayerCancel = true;

	// Whether to block all other gameplay on the player while spinning
	UPROPERTY(Category = "Gameplay")
	bool bBlockOtherGameplay = true;

	// Whether to display the default stick spin widget or not
	UPROPERTY(Category = "Stick Spin Widget")
	bool bShowStickSpinWidget = true;

	// Which component to attach the widget to
	UPROPERTY(Category = "Stick Spin Widget", Meta = (EditCondition = "bShowStickSpinWidget", EditConditionHides))
	USceneComponent WidgetAttachComponent;

	// Position offset for the widget from its attachment. If no attachment, world position.
	UPROPERTY(Category = "Stick Spin Widget", Meta = (EditCondition = "bShowStickSpinWidget", EditConditionHides))
	FVector WidgetPositionOffset;
};

enum EStickSpinDirection
{
	NotSpinning,
	SpinClockwise,
	SpinCounterClockwise,
}

struct FStickSpinState
{
	// Current direction that the input is spinning in
	UPROPERTY(Category = "Stick Spin")
	EStickSpinDirection Direction = EStickSpinDirection::NotSpinning;

	// Position relative to the start (in full cycles). Positive is clockwise relative to the start position.
	UPROPERTY(Category = "Stick Spin")
	float SpinPosition = 0.0;

	// Current velocity that we're spinning at at the moment
	UPROPERTY(Category = "Stick Spin")
	float SpinVelocity = 0.0;

	bool opEquals(FStickSpinState Other) const
	{
		return Direction == Other.Direction
		    && SpinPosition == Other.SpinPosition
		    && SpinVelocity == Other.SpinVelocity
			;
	}
};