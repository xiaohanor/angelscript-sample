
event void FThreeShotEvent(AHazePlayerCharacter Player, UThreeShotInteractionComponent Interaction);

/**
 * A one-shot animation interaction.
 *
 * The player can interact, plays an animation, and then exits the interaction automatically.
 */
class UThreeShotInteractionComponent : UInteractionComponent
{
	default bPlayerCanCancelInteraction = true;
	default MovementSettings = FMoveToParams::SmoothTeleport();
	default InteractionSheet = ThreeShotInteractionSheet;

    UPROPERTY(EditAnywhere, Category = "Three Shot Interaction")
	TPerPlayer<FThreeShotSettings> ThreeShotSettings;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnEnterBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnEnterBlendingOut;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnMHBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnMHBlendingOut;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnExitBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnExitBlendingOut;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotEvent OnCancelPressed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
};

struct FThreeShotSettings
{
	// Animation that plays once when entering the interaction
	UPROPERTY(EditAnywhere, Category = "Three Shot Animation")
	UAnimSequence EnterAnimation;

	// Animation that loops while inside the interaction
	UPROPERTY(EditAnywhere, Category = "Three Shot Animation", DisplayName = "MH Animation")
	UAnimSequence MHAnimation;

	// Animation that plays once when exiting the interaction
	UPROPERTY(EditAnywhere, Category = "Three Shot Animation")
	UAnimSequence ExitAnimation;

	// Blend time from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Three Shot Animation")
	float BlendTime = 0.2;

	// Type of blending to use from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "Three Shot Animation", AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;

	// Audio event to play when the player enters the interaction
	UPROPERTY(EditAnywhere, Category = "Three Shot Audio")
	UHazeAudioEvent EnterAudio;

	// Audio event to play when the player exits the interaction
	UPROPERTY(EditAnywhere, Category = "Three Shot Audio")
	UHazeAudioEvent ExitAudio;
};

asset ThreeShotInteractionSheet of UHazeCapabilitySheet
{
	AddCapability(n"ThreeShotInteractionCapability");

	Blocks.Add(n"Movement");
	Blocks.Add(n"GameplayAction");
};