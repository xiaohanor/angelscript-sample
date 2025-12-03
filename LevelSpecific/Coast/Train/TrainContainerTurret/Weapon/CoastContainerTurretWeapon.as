UCLASS(Abstract)
class ACoastContainerTurretWeapon : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"CoastContainerTurretWeaponCompoundCapability");

	ACoastContainerTurret Turret;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent)
	UCoastContainerTurretWeaponDamageComponent DamageComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UCoastContainerTurretWeaponMuzzleComponent Muzzle;

	UPROPERTY(DefaultComponent)
	UCoastContainerTurretWeaponAttackComponent AttackComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::OnlyShowWhenHurt, this);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector(0,0,450), this);
	}
}