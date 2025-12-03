UCLASS(Abstract, HideCategories="Cooking Collision AssetUserData ComponentReplication Variable Activation")
class UBlizzardArrowPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

    UPROPERTY(Category = "Blizzard Arrow")
	TSubclassOf<ABlizzardArrow> BlizzardArrowClass;

	UPROPERTY(Category = "Blizzard Arrow")
	protected UBlizzardArrowSettings DefaultBlizzardArrowSettings;

	AHazePlayerCharacter Player = nullptr;
	ABlizzardArrow CurrentArrow = nullptr;
	bool bShowTutorial = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplyDefaultSettings(DefaultBlizzardArrowSettings);
    }

	float GetArrowSpeed() const
	{
		return Settings.LaunchSpeed;
	}

    float GetArrowGravity() const
	{
		return Settings.Gravity;
	}

    UBlizzardArrowSettings GetSettings() const property
	{
		return UBlizzardArrowSettings::GetSettings(Player);
	}
}