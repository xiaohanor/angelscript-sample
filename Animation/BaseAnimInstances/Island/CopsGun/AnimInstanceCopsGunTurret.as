
enum ECopsGunAnimationStatus
{
	None,
	Hacking,
	Turret
}

class UAnimInstanceCopsGunTurret : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animation|Aim")
	FHazePlaySequenceData AimPose;

    UPROPERTY(BlueprintReadOnly, Category = "Animation|Hacking")
	FHazePlaySequenceData HackingEnter;

    UPROPERTY(BlueprintReadOnly, Category = "Animation|Hacking")
    FHazePlaySequenceData HackingMH;

	UPROPERTY(BlueprintReadOnly, Category = "Weapon")
	ACopsGunTurret Weapon;

	UPROPERTY(BlueprintReadOnly, Category = "Weapon")
	ECopsGunAnimationStatus AnimState = ECopsGunAnimationStatus::None;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor != nullptr)
			Weapon = Cast<ACopsGunTurret>(HazeOwningActor);
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		AnimState = ECopsGunAnimationStatus::None;
		if(Weapon != nullptr && Weapon.CurrentAttachment != nullptr)
		{
			if(Weapon.IsAttachedToWeaponPoint())
				AnimState = ECopsGunAnimationStatus::Turret;
			else if(Weapon.IsAttachedToHackingPoint())
				AnimState = ECopsGunAnimationStatus::Hacking;
		}
    }
}
