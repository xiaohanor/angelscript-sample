
class UPlayerCrouchComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FPlayerCrouchAnimData AnimData;

	TInstigated<float> MovementSpeedMultiplier;
	default MovementSpeedMultiplier.DefaultValue = 1.0;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSetting;

	UPROPERTY()
	float CameraSettingBlendTime = 2;

	UPlayerCrouchSettings Settings;
	private AHazePlayerCharacter Player;
	private TArray<FInstigator> CrouchInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UPlayerCrouchSettings::GetSettings(Player);
	}

	float GetMovementTargetSpeed(float SpeedAlpha, bool SprintSpeed = false) const
	{
		float MaxSpeed = Settings.MaximumSpeed;
		if(SprintSpeed)
			MaxSpeed = Settings.SprintMaximumSpeed;

		float MinSpeed = SprintSpeed ? Settings.SprintMinimumSpeed : Settings.MinimumSpeed;

		return Math::Lerp(MinSpeed, MaxSpeed, SpeedAlpha) * MovementSpeedMultiplier.Get();
	}

	void ApplyCrouch(FInstigator Instigator)
	{
		CrouchInstigators.Add(Instigator);
	}

	void ClearCrouch(FInstigator Instigator)
	{
		CrouchInstigators.Remove(Instigator);
	}

	bool GetbCrouching() const property
	{
		return CrouchInstigators.Num() > 0;
	}
}

struct FPlayerCrouchAnimData
{
}

mixin void ApplyCrouch(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto CrouchComp = UPlayerCrouchComponent::GetOrCreate(Player);
	CrouchComp.ApplyCrouch(Instigator);
}

mixin void ClearCrouch(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto CrouchComp = UPlayerCrouchComponent::GetOrCreate(Player);
	CrouchComp.ClearCrouch(Instigator);
}