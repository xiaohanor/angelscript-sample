event void FSketchbookOnMeleeAttacked(FSketchbookMeleeAttackData AttackData);

class USketchbookMeleeAttackableComponent : UActorComponent
{
	UPROPERTY(Meta = (BPCannotCallEvent))
	FSketchbookOnMeleeAttacked OnAttacked;

	void OnPlayerMeleeAttack(FSketchbookMeleeAttackData AttackData)
	{
		OnAttacked.Broadcast(AttackData);
	}
};