class UCoastBomblingDamageComponent : UActorComponent
{
	UPROPERTY(DefaultComponent)
	UCoastShoulderTurretGunResponseComponent ShoulderTurretResponseComp;

	UCoastBomblingSettings Settings;
	UBasicAICharacterMovementComponent MovementComponent;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UCoastBomblingSettings::GetSettings(Cast<AHazeActor>(Owner));
		ShoulderTurretResponseComp = UCoastShoulderTurretGunResponseComponent::GetOrCreate(Owner);
		ShoulderTurretResponseComp.OnBulletHit.AddUFunction(this, n"OnBulletHit");
		MovementComponent = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void OnBulletHit(FCoastShoulderTurretBulletHitParams Params)
	{
		// FVector Direction = (Owner.ActorLocation - Params.ImpactPoint).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		// MovementComponent.AddPendingImpulse(Direction * 500);
		HealthComp.TakeDamage(Params.Damage * Settings.DamageFactor, EDamageType::Default, Params.PlayerInstigator);
	}
}