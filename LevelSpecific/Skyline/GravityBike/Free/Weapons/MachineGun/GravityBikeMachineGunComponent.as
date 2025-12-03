UCLASS(Abstract, HideCategories = "ComponentTick Debug Activation Cooking Disable Tags Navigation")
class UGravityBikeMachineGunComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGravityBikeMachineGun> MachineGunClass;

	UPROPERTY(EditDefaultsOnly)
	UPlayerAimingSettings PlayerAimingSettings;

	private AHazePlayerCharacter Player;
	FGravityBikeWeaponTargetData AimTarget;
	AGravityBikeMachineGun MachineGun;
	float TimeLastFired;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void SpawnAndEquip()
	{
		if(IsEquipped())
			return;
		
		MachineGun = SpawnActor(MachineGunClass);

		auto DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);
		auto GravityBike = DriverComp.GetGravityBike();

		MachineGun.AttachToComponent(GravityBike.MeshPivot);
		MachineGun.ActorRelativeTransform = MachineGun.GravityBikeRelativeTransform;
		MachineGun.RequestComp.StartInitialSheetsAndCapabilities(Player, this);
	}

	void UnequipAndDestroy()
	{
		MachineGun.RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		MachineGun.DestroyActor();
		MachineGun = nullptr;
	}

	bool IsEquipped() const
	{
		return MachineGun != nullptr;
	}
};