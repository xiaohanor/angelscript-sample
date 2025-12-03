struct FIslandDroidZiplinePlayerAnimationData
{
	float HorizontalDistanceToDroid;
	float VerticalDistanceToDroid;
	float SidewaysTiltInput;
}

UCLASS(Abstract)
class UIslandDroidZiplinePlayerComponent : UActorComponent
{
	UPROPERTY()
	UIslandDroidZiplinePlayerSettings DefaultSettings;

	UPROPERTY()
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;

	UPROPERTY()
	UForceFeedbackEffect AttachFF;

	UPROPERTY()
	UForceFeedbackEffect CrashFF;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CrashCamShake;

	AIslandDroidZipline CurrentDroidZipline;
	UIslandDroidZiplineAttachTargetable CurrentTargetable;
	FTransform ExpectedDroidTransform;
	bool bAttached = false;
	AHazePlayerCharacter Player;
	FIslandDroidZiplinePlayerAnimationData AnimData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		if(DefaultSettings != nullptr)
			Player.ApplyDefaultSettings(DefaultSettings);
	}
}