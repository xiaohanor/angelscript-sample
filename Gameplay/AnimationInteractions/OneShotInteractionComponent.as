
event void FOneShotEvent(AHazePlayerCharacter Player, UOneShotInteractionComponent Interaction);

/**
 * A one-shot animation interaction.
 *
 * The player can interact, plays an animation, and then exits the interaction automatically.
 */
class UOneShotInteractionComponent : UInteractionComponent
{
	default bPlayerCanCancelInteraction = false;
	default MovementSettings = FMoveToParams::SmoothTeleport();
	default InteractionSheet = OneShotInteractionSheet;

    UPROPERTY(EditAnywhere, Category = "One Shot Interaction")
	TPerPlayer<FOneShotSettings> OneShotSettings;

    /* Executed when the one shot animation for this interaction has finished blending in. */
    UPROPERTY(Category = "One Shot Interaction")
    FOneShotEvent OnOneShotBlendedIn;

    /* Executed when the one shot animation for this interaction has finished playing and has started blending out. */
    UPROPERTY(Category = "One Shot Interaction")
    FOneShotEvent OnOneShotBlendingOut;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	// Override this function in potential child classes.
	FOneShotSettings GetOneShotSettingsForPlayer(AHazePlayerCharacter Player) const
	{
		return OneShotSettings[Player];
	}

	// Override this function in potential child classes.
	UHazeSkeletalMeshComponentBase GetMeshForPlayer(AHazePlayerCharacter Player) const
	{
		return Player.Mesh;
	}
};

struct FOneShotSettings
{
	// Animation to play when the player interacts
	UPROPERTY(EditAnywhere, Category = "One Shot Animation")
	UAnimSequence Animation;

	// Blend time from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "One Shot Animation")
	float BlendTime = 0.2;

	// Type of blending to use from the player's previous animation
	UPROPERTY(EditAnywhere, Category = "One Shot Animation", AdvancedDisplay)
    EHazeBlendType BlendType = EHazeBlendType::BlendType_Inertialization;

	// Audio event to play when the player interacts
	UPROPERTY(EditAnywhere, Category = "One Shot Audio")
	UHazeAudioEvent AudioEvent;

	FHazePlaySlotAnimationParams ToPlaySlotAnimParams() const
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = Animation;
		Params.BlendTime = BlendTime;
		Params.BlendType = BlendType;
		return Params;
	}

	FHazeStopSlotAnimationByAssetParams ToStopAnimByAssetParams() const
	{
		FHazeStopSlotAnimationByAssetParams Params;
		Params.Animation = Animation;
		return Params;
	}
};

asset OneShotInteractionSheet of UHazeCapabilitySheet
{
	AddCapability(n"OneShotInteractionCapability");

	Blocks.Add(n"Movement");
	Blocks.Add(n"GameplayAction");
};