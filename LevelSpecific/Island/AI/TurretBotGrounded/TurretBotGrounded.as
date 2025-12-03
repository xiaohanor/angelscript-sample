
UCLASS(Abstract)
class AAIIslandTurretBotGrounded : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"IslandTurretBotGroundedCompoundCapability");

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftWeapon;

	UPROPERTY(DefaultComponent, Attach = LeftWeapon)
	UBasicAIProjectileLauncherComponent LeftWeaponComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightWeapon;

	UPROPERTY(DefaultComponent, Attach = RightWeapon)
	UBasicAIProjectileLauncherComponent RightWeaponComponent;

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandNunchuckTargetableComponent NunchuckTargetableComp;
	default NunchuckTargetableComp.TargetableRange.Max = 1500;
	default NunchuckTargetableComp.GroundedType = EIslandNunchuckMeleeTargetableType::Grounded;
	default NunchuckTargetableComp.bTargetIsStationary = true;

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandNunchuckDamageableComponent NunchuckDamageComp;
	default NunchuckDamageComp.DamageSettings = TurretBotHeavyNunchuckDamageSettings;

	default MoveToComp.DefaultSettings = BasicAICharacterGroundIgnorePathfindingSettings;

}

/** Heavy turret bot damage amount */
asset TurretBotHeavyNunchuckDamageSettings of UIslandNunchuckDamageSettings
{
	Light = 0.1;
	Normal = 0.25;
	Heavy = 0.5;
}
