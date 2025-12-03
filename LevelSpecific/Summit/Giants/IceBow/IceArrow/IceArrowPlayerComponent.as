UCLASS(Abstract, HideCategories="Cooking Collision AssetUserData ComponentReplication Variable Activation")
class UIceArrowPlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

    UPROPERTY(Category = "Ice Arrow")
	TSubclassOf<AIceArrow> IceArrowClass;

	UPROPERTY(Category = "Ice Arrow")
	protected UIceArrowSettings DefaultIceArrowSettings;

	AHazePlayerCharacter Player = nullptr;
    UIceBowPlayerComponent IceBowPlayerComp = nullptr;
	UHazeActorNetworkedSpawnPoolComponent IceArrowPool = nullptr;
	bool bShowTutorial = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Player = Cast<AHazePlayerCharacter>(Owner);
        IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
		Player.ApplyDefaultSettings(DefaultIceArrowSettings);

		IceArrowPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(IceArrowClass, Player);
    }

	float GetArrowSpeed() const
	{
		return Math::Lerp(Settings.MinLaunchSpeed, Settings.MaxLaunchSpeed, IceBowPlayerComp.GetChargeFactor());
	}

    float GetArrowGravity() const
	{
		return Math::Lerp(Settings.MinChargeGravity, Settings.MaxChargeGravity, IceBowPlayerComp.GetChargeFactor());
	}

    AIceArrow ReadyProjectile_Control(FHazeActorSpawnParameters SpawnParams)
	{
		return Cast<AIceArrow>(IceArrowPool.SpawnControl(SpawnParams));
	}

	void RecycleIceArrow(AIceArrow IceArrow)
	{
		if (IceArrow == nullptr)
			return;

		IceArrow.Deactivate();
		IceArrowPool.UnSpawn(IceArrow);
	}
	
    UIceArrowSettings GetSettings() const property
	{
		return UIceArrowSettings::GetSettings(Player);
	}
}