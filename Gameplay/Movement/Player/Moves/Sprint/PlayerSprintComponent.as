


class UPlayerSprintComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FPlayerSprintAnimData AnimData;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SprintOverspeedAccelerationCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve SprintOverspeedDeccelerationCurve;
	
	UPROPERTY()
	private UPlayerSprintSettings DefaultSettings;	

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset SprintCameraSetting;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SprintShake;

	bool bSprintToggledOffWhileMoving = false;
	
	// Force the spring capability into activation if true
	private TArray<FInstigator> SprintForcedInstigators;

	// If we have sprint blockers, no sprinting can activate
	private TArray<FInstigator> SprintBlockers;

	private bool bSprintActive = false;
	private bool bSprintToggled = false;
	private bool bShouldOverspeed = false;

	private uint SprintToggledOnFrame = 0;

	private AHazePlayerCharacter Player;
	private UPlayerSprintSettings SettingsInternal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		if(DefaultSettings != nullptr)
			Player.ApplyDefaultSettings(DefaultSettings);

		SettingsInternal = UPlayerSprintSettings::GetSettings(Player);		
	}

	void SetSprintToggled(bool SprintToggled, bool bAllowOverspeed = true)
	{
		bSprintToggled = SprintToggled;

		if(SprintToggled && bAllowOverspeed)
			SprintToggledOnFrame = Time::FrameNumber;
	}

	void SetSprintActive(bool bStatus)
	{
		bSprintActive = bStatus;
	}

	void ForceSprint(FInstigator Instigator)
	{
		SprintForcedInstigators.Add(Instigator);
	}

	void ClearForceSprint(FInstigator Instigator)
	{
		SprintForcedInstigators.RemoveSingleSwap(Instigator);
	}

	void BlockSprint(FInstigator Instigator)
	{
		SprintBlockers.Add(Instigator);
	}

	void ClearBlockSprint(FInstigator Instigator)
	{
		SprintBlockers.RemoveSingleSwap(Instigator);
	}

	UPlayerSprintSettings GetSettings() property
	{
		return SettingsInternal;
	}

	bool IsSprinting() const
	{
		return bSprintActive;
	}
	
	bool ShouldOverspeed() const
	{
		return SprintToggledOnFrame >= Time::FrameNumber - 2;
	}
	
	bool IsForcedToWalk() const
	{
		return SprintBlockers.Num() > 0;
	}

	bool IsForcedToSprint() const
	{
		return SprintForcedInstigators.Num() > 0;
	}

	bool IsSprintToggled() const
	{
		return bSprintToggled;
	}
}

struct FPlayerSprintAnimData
{
	UPROPERTY()
	bool bWantsToMove = false;

	UPROPERTY()
	bool bTriggerSprintActivationAnim = false;
}