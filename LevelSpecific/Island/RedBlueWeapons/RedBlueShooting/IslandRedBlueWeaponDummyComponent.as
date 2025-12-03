// This component exists only so we have attached weapons in Island_Entrance
UCLASS(Abstract)
class UIslandRedBlueWeaponDummyComponent : UActorComponent
{
	UPROPERTY(Category = "Settings")
	private EIslandRedBlueWeaponType WeaponType = EIslandRedBlueWeaponType::MAX;

	UPROPERTY(Category = "Settings")
	private TSubclassOf<AIslandRedBlueWeapon> WeaponClass;

	UPROPERTY(Category = "Settings", AdvancedDisplay)
	private TArray<FIslandRedBlueWeaponComponentData> WeaponInternals;
	default WeaponInternals.SetNum(EIslandRedBlueWeaponHandType::MAX);

	default WeaponInternals[EIslandRedBlueWeaponHandType::Left].HandAttachSocket = n"LeftAttach";
	default WeaponInternals[EIslandRedBlueWeaponHandType::Right].HandAttachSocket = n"RightAttach";
	default WeaponInternals[EIslandRedBlueWeaponHandType::Left].HandAttachRelativeOffset = FTransform(FRotator(0, -90, 90));
	default WeaponInternals[EIslandRedBlueWeaponHandType::Right].HandAttachRelativeOffset = FTransform(FRotator(0, -90, 90));

	default WeaponInternals[EIslandRedBlueWeaponHandType::Left].ThighAttachSocket = n"LeftLegGunAttachSocket";
	default WeaponInternals[EIslandRedBlueWeaponHandType::Right].ThighAttachSocket = n"RightLegGunAttachSocket";

	private AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		// Spawn Left Hand
		{
			auto Weapon = SpawnActor(WeaponClass, bDeferredSpawn = true);
			InitializeWeapon(Weapon, EIslandRedBlueWeaponHandType::Left);
		}

		// Spawn Right Hand
		{
			auto Weapon = SpawnActor(WeaponClass, bDeferredSpawn = true);
			InitializeWeapon(Weapon, EIslandRedBlueWeaponHandType::Right);
		}
	}

	private void InitializeWeapon(AIslandRedBlueWeapon Weapon, EIslandRedBlueWeaponHandType Hand)
	{
		Weapon.WeaponType = WeaponType;
		Weapon.HandType = Hand;
		Weapon.PlayerOwner = PlayerOwner;
		Outline::AddToPlayerOutlineActor(Weapon, PlayerOwner, this, EInstigatePriority::Level);
		WeaponInternals[Hand].Weapon = Weapon;
		FinishSpawningActor(Weapon);
		Internal_AttachSpecificWeaponToThigh(Hand);
	}

	private void Internal_AttachSpecificWeaponToThigh(EIslandRedBlueWeaponHandType Hand)
	{
		FIslandRedBlueWeaponComponentData Data = WeaponInternals[Hand];
		Data.Weapon.AttachToComponent(PlayerOwner.Mesh, Data.ThighAttachSocket);
		Data.Weapon.SetActorRelativeTransform(Data.ThighAttachRelativeOffset);
		UIslandRedBlueWeaponEffectHandler::Trigger_OnWeaponAttachToThigh(WeaponInternals[Hand].Weapon);
	}

	void DisableWeapons()
	{
		WeaponInternals[EIslandRedBlueWeaponHandType::Left].Weapon.AddActorDisable(this);
		WeaponInternals[EIslandRedBlueWeaponHandType::Right].Weapon.AddActorDisable(this);
	}

	void EnableWeapons()
	{
		WeaponInternals[EIslandRedBlueWeaponHandType::Left].Weapon.RemoveActorDisable(this);
		WeaponInternals[EIslandRedBlueWeaponHandType::Right].Weapon.RemoveActorDisable(this);
	}
}

namespace IslandRedBlueWeaponDummyStatics
{
	UFUNCTION()
	void IslandEntranceEnableWeapons(AHazePlayerCharacter Player)
	{
		auto DummyComp = UIslandRedBlueWeaponDummyComponent::Get(Player);
		DummyComp.EnableWeapons();
	}

	UFUNCTION()
	void IslandEntranceDisableWeapons(AHazePlayerCharacter Player)
	{
		auto DummyComp = UIslandRedBlueWeaponDummyComponent::Get(Player);
		DummyComp.DisableWeapons();
	}
}