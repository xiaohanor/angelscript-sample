
class USkylineTorHammerHurtReactionBehaviour : UBasicBehaviour
{	
	USkylineTorHammerComponent HammerComp;
	UGravityBladeCombatTargetComponent BladeCombatTargetComp;
	USkylineTorSettings Settings;

	float Duration = 0.5;
	FHazeAcceleratedRotator AccRotation;
	FRotator OriginalRotation;
	FRotator TargetRotation;

	FHazeAcceleratedVector AccLocation;
	FVector OriginalLocation;
	FVector TargetLocation;

	bool bDamaged;
	FVector DamageDirection;
	FVector DamageLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineTorSettings::GetSettings(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		BladeCombatTargetComp = UGravityBladeCombatTargetComponent::GetOrCreate(Owner);

		UGravityBladeCombatResponseComponent BladeResponse = UGravityBladeCombatResponseComponent::GetOrCreate(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(BladeCombatTargetComp.IsDisabled())
			return;
		if(!Settings.ShieldBreakModeEnabled)
			return;
		bDamaged = true;
		DamageLocation = HitData.ImpactPoint;
		DamageDirection = (Owner.ActorLocation - CombatComp.Owner.ActorLocation).GetSafeNormal2D();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bDamaged)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bDamaged = false;

		bool bInverted = HammerComp.HoldHammerComp.Hammer.ActorUpVector.DotProduct(FVector::UpVector) < 0;

		if(bInverted)
			HammerComp.HoldHammerComp.Hammer.InvertedFauxRotateComp.ApplyImpulse(DamageLocation, DamageDirection * 1500);
		else
			HammerComp.HoldHammerComp.Hammer.FauxRotateComp.ApplyImpulse(DamageLocation, DamageDirection * 1500);
	}
}