UCLASS(Abstract)
class ATazerBotRespawnPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftHatchRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightHatchRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BotAttachComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenHatchesTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike LaunchBotTimeLike;

	ATazerBot AttachedRobot;
	
	UPROPERTY(EditAnywhere)
	UHazeAudioEvent RespawnAudioEvent;

	bool bOpening = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenHatchesTimeLike.BindUpdate(this, n"UpdateOpenHatches");
		OpenHatchesTimeLike.BindFinished(this, n"FinishOpenHatches");

		LaunchBotTimeLike.BindUpdate(this, n"UpdateLaunchBot");
		LaunchBotTimeLike.BindFinished(this, n"FinishLaunchBot");
	}

	void RespawnRobot(ATazerBot TazerBot)
	{
		AttachedRobot = TazerBot;
		BP_RespawnRobot();

		auto FireForgetParams = FHazeAudioFireForgetEventParams();
		FireForgetParams.AttachComponent = BotAttachComp;
		FireForgetParams.AttenuationScaling = 5000;
		
		AudioComponent::PostFireForget(RespawnAudioEvent, FireForgetParams);

		bOpening = true;
		OpenHatchesTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void LaunchBot()
	{
		LaunchBotTimeLike.PlayFromStart();
	}

	UFUNCTION(BlueprintEvent)
	void BP_RespawnRobot() {}

	UFUNCTION()
	private void UpdateOpenHatches(float CurValue)
	{
		float Scale = Math::Lerp(1.0, 0.0, CurValue);
		RightHatchRoot.SetRelativeScale3D(FVector(1.0, Scale, 1.0));
		LeftHatchRoot.SetRelativeScale3D(FVector(1.0, Scale, 1.0));
	}

	UFUNCTION()
	private void FinishOpenHatches()
	{
		if (bOpening)
		{
			Timer::SetTimer(this, n"CloseHatches", 0.5);
			Timer::SetTimer(this, n"LaunchBot", 0.5);
		}
	}

	UFUNCTION()
	private void CloseHatches()
	{
		bOpening = false;
		OpenHatchesTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	private void UpdateLaunchBot(float CurValue)
	{
		float Offset = Math::Lerp(-230.0, 6.0, CurValue);
		BotAttachComp.SetRelativeLocation(FVector(-20.0, 0.0, Offset));
	}

	UFUNCTION()
	private void FinishLaunchBot()
	{
		FinishRespawning();
	}

	UFUNCTION()
	void FinishRespawning()
	{
		AttachedRobot.FinishRespawning();

		BP_BotLanded();

		BotAttachComp.SetRelativeLocation(FVector(-20.0, 0.0, -230.0));
	}

	UFUNCTION(BlueprintEvent)
	void BP_BotLanded() {}
}