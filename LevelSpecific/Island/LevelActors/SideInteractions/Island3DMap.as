class AIsland3DMap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MapRoot;

	UPROPERTY(DefaultComponent, Attach = MapRoot)
	USceneComponent BigMapRoot;

	UPROPERTY(DefaultComponent, Attach = MapRoot)
	USceneComponent SmallMapRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedSmallMapYaw;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt TutorialPromptRotateMap;

	UPROPERTY(EditDefaultsOnly)
	float RotateSpeedDegrees = 90.0;

	UPROPERTY()
	FHazeTimeLike ScaleTimeLike;
	default ScaleTimeLike.UseSmoothCurveZeroToOne();
	default ScaleTimeLike.Duration = 1.0;

	AHazePlayerCharacter LookingPlayer;

	FRotator OGSmallMapRootRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScaleTimeLike.BindUpdate(this, n"ScaleTimeLikeUpdate");
		SmallMapRoot.SetRelativeScale3D(FVector(0.0));
		SyncedSmallMapYaw.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		OGSmallMapRootRotation = SmallMapRoot.RelativeRotation;
	}

	UFUNCTION()
	void LookAtMap(AHazePlayerCharacter Player = nullptr)
	{
		ScaleTimeLike.Play();
		LookingPlayer = Player;
		SyncedSmallMapYaw.OverrideControlSide(Player);
		UIsland3DMapEventHandler::Trigger_LookAtMap(this);
		if (Player != nullptr)
		{
			UIsland3DMapPlayerComponent MapComponent = UIsland3DMapPlayerComponent::Get(Player);
			MapComponent.IslandMap = this;
		}
	}

	UFUNCTION()
	void StopLookAtMap()
	{
		ScaleTimeLike.Reverse();
		UIsland3DMapEventHandler::Trigger_StopLookAtMap(this);
		if (LookingPlayer != nullptr)
		{
			UIsland3DMapPlayerComponent MapComponent = UIsland3DMapPlayerComponent::Get(LookingPlayer);
			MapComponent.IslandMap = nullptr;
		}
		LookingPlayer = nullptr;
	}

	UFUNCTION()
	private void ScaleTimeLikeUpdate(float CurrentValue)
	{
		float SmallAlpha = CurrentValue;
		float BigAlpha = 1 - CurrentValue;
		BigMapRoot.SetRelativeScale3D(FVector(BigAlpha));
		SmallMapRoot.SetRelativeScale3D(FVector(SmallAlpha));
		MapRoot.SetRelativeRotation(FRotator(0.0, CurrentValue * 180.0, 0.0));
	}

	UFUNCTION()
	private void SwitchMap()
	{
		if (ScaleTimeLike.IsReversed())
		{
			ScaleTimeLike.Play();
		}
		else
		{
			ScaleTimeLike.Reverse();
		}
	}
};