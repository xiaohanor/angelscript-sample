
UCLASS(Abstract)
class USketchbookMeleeWeaponPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	USketchbookMeleeWeaponSettings WeaponSettings;
	
	UPROPERTY(EditDefaultsOnly)
	const float ForwardImpulse = 400;

	AHazePlayerCharacter Player = nullptr;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
	
	void EquipWeapon()
	{
		USketchbookMeleeAttackPlayerComponent AttackComp = USketchbookMeleeAttackPlayerComponent::Get(Player);
		if(AttackComp.CurrentWeapon != nullptr)
			AttackComp.CurrentWeapon.UnequipWeapon();
		
		AttackComp.CurrentWeapon = this;

		// if(WeaponSettings != nullptr)
		// 	Player.ApplyDefaultSettings(WeaponSettings);

		// WeaponSettings = USketchbookMeleeWeaponSettings::GetSettings(Player);
	}

	void UnequipWeapon()
	{
		USketchbookMeleeAttackPlayerComponent::Get(Player).CurrentWeapon = nullptr;
	}

	void OnAttack(FSketchbookMeleeAttackData AttackData)
	{
	}

	FVector GetWeaponAttackLocation()
	{
		return FVector::ZeroVector;
	}
}
