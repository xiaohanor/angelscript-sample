class UScorpionSiegeOperatorApproachWeaponBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	AScorpionSiegeOperator Operator;
	UScorpionSiegeOperatorOperationComponent OperationComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Operator = Cast<AScorpionSiegeOperator>(Owner);
		OperationComp = UScorpionSiegeOperatorOperationComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(OperationComp.TargetWeapon != nullptr && !OperationComp.bOperating)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(OperationComp.TargetWeapon == nullptr || OperationComp.bOperating)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowards(OperationComp.OperatorSlot.WorldLocation, 400.0);

		if(OperationComp.bOperating || !OperationComp.TargetWeapon.Manager.CanOperate(Operator))
			return;

		if(!Overlap::QueryShapeOverlap(OperationComp.OperatorSlot.GetCollisionShape(), OperationComp.OperatorSlot.WorldTransform, Operator.CapsuleComponent.GetCollisionShape(), Operator.CapsuleComponent.WorldTransform))
			return;
		OperationComp.TargetWeapon.Manager.Operate(Operator);
	}
}