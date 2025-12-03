
enum EScifiPlayerCopsGunType
{
	Left,
	Right,
	MAX
}

enum EScifiPlayerCopsGunState
{
	UnEquiped,
	AttachToThigh,
	AttachToHand,
	AttachedToTarget,
	MovingToTarget,
	Recalled,
	MAX
}

enum EScifiPlayerCopsGunTargetMovementType
{
	None,
	RotateAround,
	MAX
}

enum EScifiPlayerCopsGunAttachTargetType
{
	Weapon,
	Hacking,
	MAX
}

struct FScifiPlayerCopsGunWeaponTarget
{
	int ReplicatedFrame;
	bool bThrowWeapon = false;
	bool bHasOverheat = false;
	USceneComponent Target;
	USceneComponent TargetAttachment;
	FVector WorldLocation;
	FVector RelativeLocation;
	FRotator RelativeRotation;
}
