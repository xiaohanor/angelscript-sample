class USketchbookMeleeAnimNotify : UAnimNotify
{

#if EDITOR
	default NotifyColor = FColor::FromHex("F7E2D3FF");
#endif

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(MeshComp.Owner == nullptr)
			return false;

		if(!MeshComp.Owner.HasControl())
			return false;

		auto AttackComp = USketchbookMeleeAttackPlayerComponent::Get(MeshComp.Owner);
		if(AttackComp == nullptr)
			return false;

		AttackComp.FinishAttack();

		// Use the current attack data ...
		FSketchbookMeleeAttackData AttackData = AttackComp.CurrentAttackData;

		// ... but update with current attack location
		if(AttackComp.CurrentWeapon != nullptr)
		{
			AttackData.WeaponLocation = AttackComp.CurrentWeapon.GetWeaponAttackLocation();
			AttackComp.AttackOverlapCheck(AttackData, AttackComp.CurrentWeapon.WeaponSettings);
		}
		
		return true;
	}
}