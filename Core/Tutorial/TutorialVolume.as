
enum ETutorialVolumeType
{
	// Show a prompt once when the player first enters the volume
	PromptOnce,
	// Continuously show a prompt while the player is inside the volume
	PromptWhileInVolume,
	// Use a tutorial capability with more specific logic for this tutorial 
	UseTutorialCapability,
}

/**
 * A volume that shows a tutorial to the player when they enter it for the first time.
 */
class ATutorialVolume : APlayerTrigger
{
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(EditAnywhere, Category = "Tutorial")
	ETutorialVolumeType VolumeType = ETutorialVolumeType::PromptWhileInVolume;

	UPROPERTY(EditAnywhere, Category = "Tutorial", Meta = (EditConditionHides, EditCondition = "VolumeType != ETutorialVolumeType::UseTutorialCapability"))
	FTutorialPrompt Prompt;

	UPROPERTY(EditAnywhere, Category = "Tutorial", Meta = (EditConditionHides, EditCondition = "VolumeType == ETutorialVolumeType::UseTutorialCapability"))
	TSubclassOf<UTutorialCapability> TutorialCapability;

	// Attach the prompt to the triggering player
	UPROPERTY(EditAnywhere, Category = "Tutorial", Meta = (EditConditionHides, EditCondition = "VolumeType != ETutorialVolumeType::UseTutorialCapability"))
	bool bAttachPromptToTriggeringPlayer;

	// Attach the prompt to this actor in world space, rather than putting the tutorial in its static HUD position
	UPROPERTY(EditAnywhere, Category = "Tutorial", Meta = (EditConditionHides, EditCondition = "!bAttachPromptToTriggeringPlayer && VolumeType != ETutorialVolumeType::UseTutorialCapability"))
	AActor AttachPromptToActor;

	// Offset in relative space to the attach actor to put the prompt
	UPROPERTY(EditAnywhere, Category = "Tutorial", Meta = (EditConditionHides, EditCondition = "bAttachPromptToTriggeringPlayer || AttachPromptToActor != nullptr"))
	FVector AttachmentRelativeOffset;

	// Offset in screen space upward from the attach actor
	UPROPERTY(EditAnywhere, Category = "Tutorial", Meta = (EditConditionHides, EditCondition = "bAttachPromptToTriggeringPlayer || AttachPromptToActor != nullptr"))
	float AttachmentScreenSpaceOffset = 100.0;

	private TPerPlayer<bool> HasTriggeredVolume;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"ShowTutorial");
		OnPlayerLeave.AddUFunction(this, n"HideTutorial");

		if (VolumeType == ETutorialVolumeType::UseTutorialCapability && TutorialCapability.IsValid())
			RequestComp.AddCapabilityToInitialStopped(TutorialCapability);
	}

	UFUNCTION()
	private void ShowTutorial(AHazePlayerCharacter Player)
	{
		if (VolumeType == ETutorialVolumeType::PromptOnce)
		{
			if (!HasTriggeredVolume[Player])
			{
				Prompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
				if(bAttachPromptToTriggeringPlayer)
					AttachPromptToActor = Player;
				if (AttachPromptToActor != nullptr)
					Player.ShowTutorialPromptWorldSpace(Prompt, this, AttachPromptToActor.RootComponent, AttachmentRelativeOffset, AttachmentScreenSpaceOffset);
				else
					Player.ShowTutorialPrompt(Prompt, this);
			}
		}
		else if (VolumeType == ETutorialVolumeType::PromptWhileInVolume)
		{
			if(bAttachPromptToTriggeringPlayer)
				AttachPromptToActor = Player;
			if (AttachPromptToActor != nullptr)
				Player.ShowTutorialPromptWorldSpace(Prompt, this, AttachPromptToActor.RootComponent, AttachmentRelativeOffset, AttachmentScreenSpaceOffset);
			else
				Player.ShowTutorialPrompt(Prompt, this);
		}
		else if (VolumeType == ETutorialVolumeType::UseTutorialCapability && TutorialCapability.IsValid())
		{
			RequestComp.StartInitialSheetsAndCapabilities(Player, this);
		}

		HasTriggeredVolume[Player] = true;
	}

	UFUNCTION()
	private void HideTutorial(AHazePlayerCharacter Player)
	{
		if (VolumeType == ETutorialVolumeType::PromptWhileInVolume || VolumeType == ETutorialVolumeType::PromptOnce)
		{
			Player.RemoveTutorialPromptByInstigator(this);
		}
		else if (VolumeType == ETutorialVolumeType::UseTutorialCapability && TutorialCapability.IsValid())
		{
			RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		}
	}
};