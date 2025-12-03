
enum ETutorialPromptDisplay
{
	Action,
	ActionHold,
	ActionRelease,

	LeftStick_UpDown,
	LeftStick_LeftRight,
	LeftStick_LeftRightUpDown,
	LeftStick_Up,
	LeftStick_Down,
	LeftStick_Left,
	LeftStick_Right,
	LeftStick_Rotate_CW,
	LeftStick_Rotate_CCW,
	LeftStick_Press,

	RightStick_UpDown,
	RightStick_LeftRight,
	RightStick_LeftRightUpDown,
	RightStick_Up,
	RightStick_Down,
	RightStick_Left,
	RightStick_Right,
	RightStick_Rotate_CW,
	RightStick_Rotate_CCW,
	RightStick_Press,

	TextOnly,
};

enum ETutorialAlternativePromptDisplay
{
	None,
	Keyboard_LeftRight,
	Keyboard_UpDown,
	Mouse_LeftRightButton
};

enum ETutorialPromptMode
{
	Default,
	RemoveWhenPressed,
};

enum ETutorialPromptState
{
	Normal,
	Unavailable,
};

struct FTutorialPrompt
{
	UPROPERTY(Meta = (EditCondition = "DisplayType == ETutorialPromptDisplay::Action || DisplayType == ETutorialPromptDisplay::ActionHold || DisplayType == ETutorialPromptDisplay::ActionRelease", EditConditionHides))
	FName Action;

	UPROPERTY()
	FText Text;

	UPROPERTY()
	ETutorialPromptDisplay DisplayType = ETutorialPromptDisplay::Action;

	UPROPERTY()
	ETutorialAlternativePromptDisplay AlternativeDisplayType = ETutorialAlternativePromptDisplay::None;

	UPROPERTY()
	ETutorialPromptMode Mode = ETutorialPromptMode::Default;

	UPROPERTY()
	float MaximumDuration = 0.0;

	// Override which player's controls are shown for the tutorial, can be used to add tutorials for the other player in fullscreen
	UPROPERTY()
	EHazeSelectPlayer OverrideControlsPlayer = EHazeSelectPlayer::None;
};

enum ETutorialPromptChainType
{
	Plus,
	Arrow,
};

struct FTutorialPromptChain
{
	UPROPERTY()
	TArray<FTutorialPrompt> Prompts;

	UPROPERTY()
	ETutorialPromptChainType Type = ETutorialPromptChainType::Plus;
};