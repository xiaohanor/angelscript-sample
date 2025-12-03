class AMenuCameraUser : AHazeAdditionalCameraUser
{
	UPROPERTY(DefaultComponent, Attach = "Root", ShowOnActor, Category = "Camera")
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UHazeCameraUserComponent UserComp;	

	UPROPERTY(DefaultComponent)
	UFadeManagerComponent FadeManagerComponent;

	UPROPERTY(DefaultComponent)
	USubtitleManagerComponent SubtitleComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	bool bIsSecondaryUser = false;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;
	default PrimaryActorTick.bTickEvenWhenPaused = true;

	UHazeCameraComponent GetActiveCamera() const property
	{
		return UserComp.ActiveCamera;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bIsSecondaryUser)
		{
			FadeManagerComponent.AddFade(this, -1.0f, 0.0f, 0.0, EFadePriority::Gameplay);
			ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant, EHazeViewPointPriority::Low);
		}
	}

	UFUNCTION()
	void FadeInView(float FadeDuration)
	{
		FadeManagerComponent.ClearFade(this, FadeDuration);
	}

	UFUNCTION()
	void FadeOutView(float FadeOutTime)
	{
		FadeManagerComponent.AddFade(this, -1.f, FadeOutTime, 0.0, EFadePriority::Gameplay);
	}

	UFUNCTION()
	void AddTemporaryFade(float FadeOutTime, float FadeDuration, float FadeInTime)
	{
		FadeManagerComponent.AddFade(this, FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Gameplay);
	}

	UFUNCTION()
	void SnapToCamera(AStaticCameraActor InCamera)
	{
		DeactivateCameraByInstigator(this, 0.0);
		ActivateCamera(InCamera, 0.0, this, EHazeCameraPriority::Minimum);
	}

	UFUNCTION()
	void BlendToCamera(AStaticCameraActor InCamera, float BlendTime)
	{
		DeactivateCameraByInstigator(this, BlendTime);
		ActivateCamera(InCamera, BlendTime, this, EHazeCameraPriority::Minimum);
	}
};

class ASecondaryMenuCameraUser : AMenuCameraUser
{
	default bIsSecondaryUser = true;
	default UserComp.SplitScreenPosition = EHazeSplitScreenPosition::SecondPlayer;
}