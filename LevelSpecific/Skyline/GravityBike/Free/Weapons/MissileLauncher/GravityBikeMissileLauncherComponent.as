UCLASS(Abstract, HideCategories = "ComponentTick Debug Activation Cooking Disable Tags Navigation")
class UGravityBikeMissileLauncherComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGravityBikeMissileLauncher> MissileLauncherClass;

	UPROPERTY(EditDefaultsOnly)
	UPlayerAimingSettings PlayerAimingSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UTargetableWidget> TargetWidgetClass;

	AHazePlayerCharacter Player; // was private
	FGravityBikeWeaponTargetData AimTarget;
	AGravityBikeMissileLauncher MissileLauncher;
	float TimeLastFired;
	bool bUseLeftMuzzle = false;

	UHazeActorLocalSpawnPoolComponent MissileSpawnPool;
	private bool bIsEquipped = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(MissileLauncher != nullptr)
			MissileLauncher.RemoveActorDisable(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(MissileLauncher != nullptr)
			MissileLauncher.AddActorDisable(Owner);
	}

	void SpawnAndEquipLauncher()
	{
		if(IsEquipped())
			return;
		
		if(MissileLauncher == nullptr)
		{
			MissileLauncher = SpawnActor(MissileLauncherClass);
			MissileLauncher.MakeNetworked(this, n"MissileLauncher");
			MissileLauncher.SetActorControlSide(this);

			auto DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);
			auto GravityBike = DriverComp.GetGravityBike();

			MissileLauncher.AttachToComponent(GravityBike.SkeletalMesh, n"Base");
			MissileLauncher.ActorRelativeTransform = MissileLauncher.GravityBikeRelativeTransform;

			if(MissileSpawnPool == nullptr)
			{
				MissileSpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(MissileLauncher.MissileClass, Player);
			}
		}
		else
		{
			MissileLauncher.RemoveActorDisable(this);
		}

		MissileLauncher.RequestComp.StartInitialSheetsAndCapabilities(Player, this);
		bIsEquipped = true;
	}

	void UnequipAndDestroyLauncher()
	{
		MissileLauncher.RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		MissileLauncher.AddActorDisable(this);
		bIsEquipped = false;
	}

	bool IsEquipped() const
	{
		return bIsEquipped;
	}

	UArrowComponent GetCurrentMuzzle() const
	{
		return bUseLeftMuzzle ? MissileLauncher.LeftMuzzle : MissileLauncher.RightMuzzle;
	}
};