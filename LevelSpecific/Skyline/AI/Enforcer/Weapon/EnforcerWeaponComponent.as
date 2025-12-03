event void FEnforcerWeaponPrime(FEnforcerWeaponPrimeData Data);

struct FEnforcerWeaponPrimeData
{
	UPROPERTY()
	float Duration;
}

namespace EnforcerWeapon
{
	UEnforcerWeaponComponent Get(AHazeActor User)
	{
		UEnforcerWeaponComponent Weapon = UEnforcerRifleComponent::Get(User);
		if (Weapon == nullptr)
		{
			UBasicAIWeaponWielderComponent WielderComp = UBasicAIWeaponWielderComponent::Get(User);
			if ((WielderComp != nullptr) && (WielderComp.Weapon != nullptr))
				Weapon = UEnforcerWeaponComponent::Get(WielderComp.Weapon);
		}
		return Weapon;
	}
}

// TODO: Do we need this class at all? Clean up!
UCLASS(Abstract)
class UEnforcerWeaponComponent : UBasicAIProjectileLauncherComponent
{
	UFUNCTION(BlueprintPure)
	AHazeActor GetWeaponActor() const property
	{
		return GetLauncherActor();
	}
}