UCLASS(Abstract, HideCategories="Cooking Collision AssetUserData ComponentReplication Variable Activation")
class URopeArrowPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

    UPROPERTY(Category = "Rope Arrow")
	TSubclassOf<ARopeArrow> RopeArrowClass;

	UPROPERTY(Category = "Rope Arrow")
	protected URopeArrowSettings DefaultRopeArrowSettings;

	AHazePlayerCharacter Player = nullptr;
	ARopeArrow CurrentArrow = nullptr;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplyDefaultSettings(DefaultRopeArrowSettings);
    }

	float GetArrowSpeed() const
	{
		return Settings.LaunchSpeed;
	}

    float GetArrowGravity() const
	{
		return Settings.Gravity;
	}

    URopeArrowSettings GetSettings() const property
	{
		return URopeArrowSettings::GetSettings(Player);
	}
}