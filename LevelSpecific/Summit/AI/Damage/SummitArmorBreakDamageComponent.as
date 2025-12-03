class USummitArmorBreakDamageComponent : UActorComponent
{	
	UAcidTailBreakableComponent AcidTailBreakComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidTailBreakComp = UAcidTailBreakableComponent::Get(Owner);
		auto TailAttackResponseComp = UTeenDragonTailAttackResponseComponent::Get(Owner);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!AcidTailBreakComp.IsWeakened())
			return;
		
		//SUPER TEMPORARY
		FOnBrokenByTailParams BreakParams;
		BreakParams.BreakLocation = Owner.ActorLocation;
		BreakParams.BreakDirection = Owner.ActorForwardVector;
		AcidTailBreakComp.OnBrokenByTail.Broadcast(BreakParams);
	}
}