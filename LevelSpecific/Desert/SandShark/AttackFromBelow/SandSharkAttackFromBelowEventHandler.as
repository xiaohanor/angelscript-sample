UCLASS(Abstract)
class USandSharkAttackFromBelowEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ASandShark SandShark;

	UPROPERTY(BlueprintReadOnly)
	USandSharkAttackFromBelowComponent AttackFromBelowComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		AttackFromBelowComp = USandSharkAttackFromBelowComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartAttackFromBelowJump()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopAttackFromBelowJump()
	{
	}
};