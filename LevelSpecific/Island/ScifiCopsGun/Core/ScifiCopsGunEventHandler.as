

struct FScifiPlayerCopsGunOnShootEventData
{
	UPROPERTY(BlueprintReadOnly)
	EScifiPlayerCopsGunType WeaponInstigator = EScifiPlayerCopsGunType::MAX;

	UPROPERTY(BlueprintReadOnly)
	AScifiCopsGunBullet Bullet;

	UPROPERTY(BlueprintReadOnly)
	FVector MuzzleLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ShootDirection;

	UPROPERTY(BlueprintReadOnly)
	float OverheatAmount;

	UPROPERTY(BlueprintReadOnly)
	float OverheatMaxAmount;
}

struct FScifiPlayerCopsGunBulletOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal = FVector::OneVector;

	UPROPERTY(BlueprintReadOnly)
	FVector ToBullet;

	UPROPERTY(BlueprintReadOnly)
	UScifiCopsGunShootTargetableComponent BulletTarget;	

	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterial PhysMat;
}

enum EScifiPlayerCopsGunWeaponAttachEventType
{
	Unset,
	PlayerHand,
	PlayerThigh,
	Wall,
	Hackpoint,
	Target
}

struct FScifiPlayerCopsGunWeaponAttachEventData
{
		// Did we attach to the players hand
	UPROPERTY(BlueprintReadOnly)
	EScifiPlayerCopsGunWeaponAttachEventType Type = EScifiPlayerCopsGunWeaponAttachEventType::Unset;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	// Did we attach to a world target
	UPROPERTY(BlueprintReadOnly)
	UScifiCopsGunThrowTargetableComponent AttachTarget;

	// Physmat for impact audio
	UPROPERTY(BlueprintReadOnly)
	UPhysicalMaterial PhysMat;

}

struct FScifiPlayerCopsGunWeaponDetachEventData
{
	// What kind of attachment did we detach from
	UPROPERTY(BlueprintReadOnly)
	EScifiPlayerCopsGunWeaponAttachEventType AttachedTypeWhenDetached = EScifiPlayerCopsGunWeaponAttachEventType::Unset;

	// Where we attached to a world target when detached
	UPROPERTY(BlueprintReadOnly)
	UScifiCopsGunThrowTargetableComponent Attachment;
}

struct FScifiPlayerCopsGunWeaponRecallEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector HandLocation;

	// Has this reached its target before we recalled it
	UPROPERTY(BlueprintReadOnly)
	bool bRecalledWhileInAir = false;
}

struct FScifiPlayerCopsGunOverheatData
{
	UPROPERTY(BlueprintReadOnly)
	float TimeUntilWeStartTheCooldown = 0;

	UPROPERTY(BlueprintReadOnly)
	float CooldownTime = 0;
}


UCLASS(Abstract)
class UScifiCopsGunEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(BlueprintReadOnly)
	AScifiCopsGun Gun = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Gun = Cast<AScifiCopsGun>(Owner);
		check(Gun != nullptr);
	}

	UFUNCTION(BlueprintPure)
	float GetDistanceToTarget() const
	{
		if(Gun == nullptr)
			return 0;
		return Gun.GetDistanceToCurrentTarget();
	}

	UFUNCTION(BlueprintPure)
	bool IsInAir() const
	{
		if(Gun == nullptr)
			return false;
		return Gun.IsInAir();
	}

	// How long have we been flying
	UFUNCTION(BlueprintPure)
	float GetInAirTime() const
	{
		if(Gun == nullptr)
			return 0;
		return Gun.GetInAirTime();
	}

	UFUNCTION(BlueprintPure)
	bool IsAttachedToHand() const
	{
		if(Gun == nullptr)
			return false;
		return Gun.IsWeaponAttachedToPlayerHand();
	}

	UFUNCTION(BlueprintPure)
	bool IsAttachedToThigh() const
	{
		if(Gun == nullptr)
			return false;
		return Gun.IsWeaponAttachedToPlayerThigh();
	}

	UFUNCTION(BlueprintPure)
	bool IsAttachedToTarget() const
	{
		if(Gun == nullptr)
			return false;
		return Gun.IsWeaponAttachedToTarget();
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAimStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAimStopped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot(FScifiPlayerCopsGunOnShootEventData OnShootData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecall(FScifiPlayerCopsGunWeaponRecallEventData OnRecallData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletImpact(FScifiPlayerCopsGunBulletOnImpactEventData OnImpactData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponAttach(FScifiPlayerCopsGunWeaponAttachEventData OnAttachData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponDetach(FScifiPlayerCopsGunWeaponDetachEventData OnDetach) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOverheat(FScifiPlayerCopsGunOverheatData OnOverheatData) {}
}


UCLASS(Abstract, Meta = (RequireActorType = "AHazePlayerCharacter"))
class UScifiPlayerCopsGunEventHandler : UHazeEffectEventHandler
{
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAimStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAimStopped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShoot(FScifiPlayerCopsGunOnShootEventData OnShootData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootStopped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecall() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponsAttach(FScifiPlayerCopsGunWeaponAttachEventData OnAttachData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponsDetach(FScifiPlayerCopsGunWeaponDetachEventData OnDetachData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowPreImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOverheat(FScifiPlayerCopsGunOverheatData OnOverheatData) {}
}