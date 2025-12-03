
event void FPlayerForceSlideVolumeStartSlideSignature(AHazePlayerCharacter Player);

enum ESlideCameraClearType
{
	OnExitShape,
	OnSlideStopped,
}

UCLASS(HideCategories = "Navigation Collision Rendering Debug Actor Cooking", Meta = (HighlightPlacement))
class APlayerForceSlideVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default SetBrushColor(FLinearColor::Green);

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(DefaultComponent)
	UArrowComponent SlideDirection;
	default SlideDirection.SetArrowColor(FLinearColor::Green);

	UPROPERTY(EditInstanceOnly, Category = "Slide")
	private bool bEnabled = true;

	UPROPERTY(EditAnywhere, Category = "Slide")
	UPlayerSlideSettings SettingsOverride;

	// How to determine the slide direction
	UPROPERTY(EditAnywhere, Category = "Slide")
	ESlideType SlideType = ESlideType::Freeform;

	//Which player should be affected by volume
	UPROPERTY(EditInstanceOnly, Category = "Slide")
	EHazeSelectPlayer AffectsPlayer = EHazeSelectPlayer::Both;

	// Spline to slide along
	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (EditCondition = "SlideType == ESlideType::SplineSlide", EditConditionHides))
	AHazeActor SlideSplineActor;

	// Whether to lock the player to be near the spline based on its scale
	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (EditCondition = "SlideType == ESlideType::SplineSlide", EditConditionHides))
	bool bConstrainToSplineWidth = false; 

	// Stop sliding immediately when exiting the volume, instead of slowing down gradually
	UPROPERTY(EditAnywhere, Category = "Slide")
	bool bStopSlideImmediately = false;

	// Skip Slide Enter Animation (if entering via Cutscene/etc)
	UPROPERTY(EditAnywhere, Category = "Slide")
	bool bSkipSlideEnterAnim = false;

	// Minimum distance we slide after leaving the volume before we stop
	UPROPERTY(EditAnywhere, Category = "Slide")
	float MinimumStopDistance = 100.0;

	// Minimum duration we continue sliding after leaving the volume
	UPROPERTY(EditAnywhere, Category = "Slide")
	float MinimumSlideStoppingDuration = 0.4;

	// Keep the same slide direction after exiting into a temporary slide when leaving the volume
	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (EditCondition = "!bStopSlideImmediately", EditConditionHides))
	bool bKeepSlideDirectionAfterExit = true;

	UPROPERTY(EditInstanceOnly, Category = "Slide")
	UHazeCameraSpringArmSettingsDataAsset CamSettingsOverride;

	UPROPERTY(EditInstanceOnly, Category = "Slide", meta = (EditCondition = "CamSettingsOverride != nullptr", EditConditionHides))
	EHazeCameraPriority CameraPriority = EHazeCameraPriority::Medium;

	UPROPERTY(EditInstanceOnly, Category = "Slide", meta = (EditCondition = "CamSettingsOverride != nullptr", EditConditionHides))
	int CameraSubPriority = 40;

	UPROPERTY(EditInstanceOnly, Category = "Slide", meta = (EditCondition = "CamSettingsOverride != nullptr", EditConditionHides))
	ESlideCameraClearType CameraSettingClearCondition;

	UPROPERTY()
	FPlayerForceSlideVolumeStartSlideSignature OnStartSlide();

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SlideDirection.SetVisibility(SlideType == ESlideType::StaticDirection);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");
	}

	UFUNCTION()
	void OnPlayerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		if(!bEnabled)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if(!Player.IsSelectedBy(AffectsPlayer))
			return;

		SetForceSlide(Player);

		if(CamSettingsOverride != nullptr)
		{
			if(CameraSettingClearCondition == ESlideCameraClearType::OnSlideStopped)
			{
				UPlayerSlideComponent SlideComp = UPlayerSlideComponent::Get(Player);

				//Store the instigator for clearing once slide stops
				if(SlideComp != nullptr)
					SlideComp.CamOverrideInstigators.AddUnique(FInstigator(this));
			}

			Player.ApplyCameraSettings(CamSettingsOverride, 1.5, this, CameraPriority, CameraSubPriority);
		}
	}

	UFUNCTION()
	void OnPlayerEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		ClearForceSlide(Player);

		if(CamSettingsOverride != nullptr && CameraSettingClearCondition == ESlideCameraClearType::OnExitShape)
			Player.ClearCameraSettingsByInstigator(this, 1.5);
	}

	UFUNCTION()
	void SetVolumeEnabled(bool bEnable)
	{
		bEnabled = bEnable;

		VerifyOverlappingActors();
	}

	void VerifyOverlappingActors()
	{
		TArray<AActor> OverlappingActors;
		GetOverlappingActors(OverlappingActors, AHazePlayerCharacter);

		for(auto Actor : OverlappingActors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

			if(Player != nullptr)
			{
				if ((Player.IsMio() && (AffectsPlayer == EHazeSelectPlayer::Mio || AffectsPlayer == EHazeSelectPlayer::Both))
					|| (Player.IsZoe() && (AffectsPlayer == EHazeSelectPlayer::Zoe ||AffectsPlayer == EHazeSelectPlayer::Both)))
				{
					if(bEnabled)
						SetForceSlide(Player);
					else
						ClearForceSlide(Player);
				}
				else
					continue;
			}
		}
	}

	FSlideParameters MakeSlideParameters()
	{
		FSlideParameters SlideParams;
		SlideParams.SlideType = SlideType;
		SlideParams.bConstrainToSplineWidth = bConstrainToSplineWidth;
		SlideParams.bSkipEnterAnim = bSkipSlideEnterAnim;

		if (SlideType == ESlideType::SplineSlide)
		{
			if (SlideSplineActor == nullptr)
				devError(f"Force slide volume {this} does not have a spline actor assigned.");

			SlideParams.SplineComp = Spline::GetGameplaySpline(SlideSplineActor, this);
		}
		else if (SlideType == ESlideType::StaticDirection)
		{
			SlideParams.SlideWorldDirection = SlideDirection.WorldRotation.ForwardVector;
		}
		return SlideParams;
	}

	void SetForceSlide(AHazePlayerCharacter Player)
	{
		if(SettingsOverride != nullptr)
			Player.ApplySettings(SettingsOverride, this);
		Player.ForcePlayerSlide(this, MakeSlideParameters());
		OnStartSlide.Broadcast(Player);
	}

	void ClearForceSlide(AHazePlayerCharacter Player)
	{
		Player.ClearForcePlayerSlide(this);
		if (!bStopSlideImmediately || MinimumSlideStoppingDuration > 0)
		{
			auto SlideComp = UPlayerSlideComponent::Get(Player);
			if (SlideComp == nullptr || SlideComp.bIsSliding)
			{
				FSlideParameters Parameters;
				if (bKeepSlideDirectionAfterExit)
					Parameters = MakeSlideParameters();

				float MaximumSlideDuration = -1.0;
				if (bStopSlideImmediately)
					MaximumSlideDuration = MinimumSlideStoppingDuration;

				Player.StartTemporaryPlayerSlide(this, Parameters, MinimumSlideStoppingDuration, MaximumSlideDuration, MinimumStopDistance);
			}
		}

		if(SettingsOverride != nullptr)
			Player.ClearSettingsByInstigator(this);
	}
}