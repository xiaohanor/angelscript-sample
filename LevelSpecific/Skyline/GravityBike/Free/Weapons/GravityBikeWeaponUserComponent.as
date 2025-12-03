#if !RELEASE
namespace DevToggleGravityBikeFree
{
	const FHazeDevToggleBool InfiniteWeaponCharge;
};
#endif

enum EGravityBikeWeaponType
{
	None,
	MachineGun,
	MissileLauncher,
};

event void FGravityBikeWeaponUserComponentOnWeaponPickupPickedUp();

UCLASS(Abstract, HideCategories = "ComponentTick Debug Activation Cooking Disable Tags Navigation")
class UGravityBikeWeaponUserComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	protected EGravityBikeWeaponType EquippedWeapon = EGravityBikeWeaponType::MachineGun;

	UPROPERTY(EditDefaultsOnly)
	float FiringMaxSpeed = 3000;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset FiringCameraSettings;

	UPROPERTY(EditDefaultsOnly)
	FText NoChargePromptText;

	UPROPERTY(EditDefaultsOnly)
	FText FirePromptText;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCrosshairWidget> CrosshairWidget;

	UPROPERTY()
	FGravityBikeWeaponUserComponentOnWeaponPickupPickedUp OnWeaponPickupPickedUp;

	private AHazePlayerCharacter Player;
	private float CurrentCharge = 0.0;
	private uint LastFiredFrame = 0;
	private float LastFiredTime = 0;

	bool bCanFireAtTarget = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

#if !RELEASE
		DevToggleGravityBikeFree::InfiniteWeaponCharge.MakeVisible();
#endif
	}

	bool HasEquipWeapon() const
	{
		return EquippedWeapon == EGravityBikeWeaponType::None;
	}

	bool HasEquipWeaponOfType(EGravityBikeWeaponType WeaponType) const
	{
		return EquippedWeapon == WeaponType;
	}

	UFUNCTION(DevFunction)
	void ChangeEquippedWeapon(EGravityBikeWeaponType NewWeaponType)
	{
		EquippedWeapon = NewWeaponType;
	}

	void AddCharge(float Fraction)
	{
		CurrentCharge = Math::Saturate(CurrentCharge + Fraction);
	}

	void DecreaseCharge(float Fraction)
	{
		CurrentCharge = Math::Saturate(CurrentCharge - Fraction);
	}
	
	float GetCurrentCharge() const
	{
#if !RELEASE
		if(DevToggleGravityBikeFree::InfiniteWeaponCharge.IsEnabled())
			return 1.0;
#endif

		return CurrentCharge;
	}

	bool HasChargeFor(float Fraction) const
	{
		return GetCurrentCharge() > Fraction;
	}

	bool HasChargeForEquippedWeapon() const
	{
		switch(EquippedWeapon)
		{
			case EGravityBikeWeaponType::None:
				return false;

			case EGravityBikeWeaponType::MachineGun:
			{
				auto MachineGunComp = UGravityBikeMachineGunComponent::Get(Player);
				if(MachineGunComp == nullptr)
					return false;

				if(!MachineGunComp.IsEquipped())
					return false;

				return HasChargeFor(MachineGunComp.MachineGun.GetChargePerShot());
			}

			case EGravityBikeWeaponType::MissileLauncher:
			{
				auto MissileLauncherComp = UGravityBikeMissileLauncherComponent::Get(Player);
				if(MissileLauncherComp == nullptr)
					return false;

				if(!MissileLauncherComp.IsEquipped())
					return false;

				return HasChargeFor(MissileLauncherComp.MissileLauncher.GetChargePerShot());
			}
		}
	}

	void UpdateIsFired()
	{
		LastFiredFrame = Time::FrameNumber;
		LastFiredTime = Time::GameTimeSeconds;
	}

	bool HasFiredThisFrame() const
	{
		return LastFiredFrame == Time::FrameNumber;
	}

	float GetLastFireTime() const
	{
		return LastFiredTime;
	}
};