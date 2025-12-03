class USkylineSniperDamageComponent : UActorComponent
{
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponse;

	UBasicAICharacterMovementComponent MovementComponent;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
		MovementComponent = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
	}
	
	UFUNCTION()
	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{			
		FVector Direction = (Owner.ActorLocation - CombatComp.Owner.ActorLocation).GetSafeNormal();
		MovementComponent.AddPendingImpulse(Direction * HitData.AttackMovementLength * 2.0);
		HealthComp.TakeDamage(HitData.Damage, HitData.DamageType, Cast<AHazeActor>(CombatComp.Owner));	
	}
}