UCLASS(Abstract, HideCategories="Cooking Collision AssetUserData ComponentReplication Variable Activation")
class UWindArrowPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

    UPROPERTY(Category = "Wind Arrow")
	TSubclassOf<AWindArrow> WindArrowClass;

	UPROPERTY(Category = "Wind Arrow")
	protected UWindArrowSettings DefaultWindArrowSettings;

	AHazePlayerCharacter Player = nullptr;
    UIceBowPlayerComponent IceBowPlayerComp = nullptr;
	UHazeActorNetworkedSpawnPoolComponent WindArrowPool = nullptr;
	bool bShowTutorial = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Player = Cast<AHazePlayerCharacter>(Owner);
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
		Player.ApplyDefaultSettings(DefaultWindArrowSettings);

		WindArrowPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(WindArrowClass, Player);
    }

	float GetArrowSpeed() const
	{
		return Math::Lerp(Settings.MinLaunchSpeed, Settings.MaxLaunchSpeed, IceBowPlayerComp.GetChargeFactor());
	}

    float GetArrowGravity() const
	{
		return Math::Lerp(Settings.MinChargeGravity, Settings.MaxChargeGravity, IceBowPlayerComp.GetChargeFactor());
	}

    AWindArrow ReadyProjectile_Control(FHazeActorSpawnParameters SpawnParams)
	{
		return Cast<AWindArrow>(WindArrowPool.SpawnControl(SpawnParams));
	}

	void RecycleWindArrow(AWindArrow WindArrow)
	{
		if (WindArrow == nullptr)
			return;

		WindArrow.Deactivate();
		WindArrowPool.UnSpawn(WindArrow);
	}
	
    UWindArrowSettings GetSettings() const property
	{
		return UWindArrowSettings::GetSettings(Player);
	}
}