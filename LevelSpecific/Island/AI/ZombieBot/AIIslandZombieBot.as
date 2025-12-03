UCLASS(Abstract)
class AAIIslandZombieBot : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"AIIslandZombieBotBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandNunchuckTargetableComponent NunchuckTargetableComp;
	default NunchuckTargetableComp.TargetableRange.Max = 800;
	default NunchuckTargetableComp.GroundedType = EIslandNunchuckMeleeTargetableType::Grounded;
	default NunchuckTargetableComp.bTargetIsStationary = false;
	default NunchuckTargetableComp.bCanTraversToTarget = false;

	UPROPERTY(DefaultComponent, Attach = "CollisionCylinder")
	UIslandNunchuckDamageableComponent NunchuckDamageComp;
	default NunchuckDamageComp.DamageSettings = ZombieBotHeavyNunchuckDamageSettings;

	default MoveToComp.DefaultSettings = BasicAICharacterGroundIgnorePathfindingSettings;
}

/** Heavy turret bot damage amount */
asset ZombieBotHeavyNunchuckDamageSettings of UIslandNunchuckDamageSettings
{
	Light = 0.5;
	Normal = 0.75;
	Heavy = 1.0;
}
