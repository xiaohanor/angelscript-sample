
UCLASS(Abstract)
class ACopsGunTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent Muzzle;

	AHazePlayerCharacter PlayerOwner;
	UScifiCopsGunThrowTargetableComponent CurrentAttachment;

	bool IsAttachedToHackingPoint() const
	{
		if(CurrentAttachment == nullptr)
			return false;

		return CurrentAttachment.Type == EScifiPlayerCopsGunAttachTargetType::Hacking;
	}

	bool IsAttachedToWeaponPoint() const
	{
		if(CurrentAttachment == nullptr)
			return false;
		
		return CurrentAttachment.Type == EScifiPlayerCopsGunAttachTargetType::Weapon;
	}
}