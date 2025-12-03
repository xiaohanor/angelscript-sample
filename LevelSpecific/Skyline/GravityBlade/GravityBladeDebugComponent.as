class UGravityBladeDebugComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto GrappleResponseComp = UGravityBladeGrappleResponseComponent::Get(Owner);
		if(GrappleResponseComp != nullptr)
		{
			GrappleResponseComp.OnThrowStart.AddUFunction(this, n"HandleThrowStart");
			GrappleResponseComp.OnThrowEnd.AddUFunction(this, n"HandleThrowEnd");
			GrappleResponseComp.OnPullStart.AddUFunction(this, n"HandlePullStart");
			GrappleResponseComp.OnPullEnd.AddUFunction(this, n"HandlePullEnd");
		}

		auto CombatResponseComp = UGravityBladeCombatResponseComponent::Get(Owner);
		if(CombatResponseComp != nullptr)
		{
			CombatResponseComp.OnHit.AddUFunction(this, n"HandleHit");
		}
	}

	UFUNCTION()
	private void HandleThrowStart(UGravityBladeGrappleUserComponent GrappleComp,
		FGravityBladeThrowData ThrowData)
	{
		Print(f"Throw Start ({GrappleComp.Owner.Name} => {Owner.Name})\n" +
			f"Location: {ThrowData.Location}\n" +
			f"Normal: {ThrowData.Normal}",
			Color = FLinearColor::DPink);
	}

	UFUNCTION()
	private void HandleThrowEnd(UGravityBladeGrappleUserComponent GrappleComp,
		FGravityBladeThrowData ThrowData)
	{
		Print(f"Throw End ({GrappleComp.Owner.Name} => {Owner.Name}\n" +
			f"Location: {ThrowData.Location}\n" +
			f"Normal: {ThrowData.Normal}",
			Color = FLinearColor::DPink);
	}

	UFUNCTION()
	private void HandlePullStart(UGravityBladeGrappleUserComponent GrappleComp)
	{
		Print(f"Pull Start ({GrappleComp.Owner.Name} => {Owner.Name})",
			Color = FLinearColor::DPink);
	}

	UFUNCTION()
	private void HandlePullEnd(UGravityBladeGrappleUserComponent GrappleComp)
	{
		Print(f"Pull End ({GrappleComp.Owner.Name} => {Owner.Name})",
			Color = FLinearColor::DPink);
	}

	UFUNCTION()
	private void HandleHit(UGravityBladeCombatUserComponent CombatComp,
		FGravityBladeHitData HitData)
	{
		Print(f"Hit ({CombatComp.Owner.Name} => {Owner.Name})\n" +
			f"Damage: {HitData.Damage}, MovementType: {HitData.MovementType}",
			Color = FLinearColor::DPink);

		Debug::DrawDebugSphere(
			HitData.ImpactPoint,
			5.0,
			16,
			FLinearColor::Red,
			3.0,
			1.0);
	}
#endif
}