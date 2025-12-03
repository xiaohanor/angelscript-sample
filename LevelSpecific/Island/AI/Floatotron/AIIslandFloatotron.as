
UCLASS(Abstract)
class AAIIslandFloatotron : ABasicAIFlyingCharacter
{
	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactCounterResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0")
	UIslandForceFieldComponent ForceFieldComp;	

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightAttach")
	UBasicAIProjectileLauncherComponent LauncherComp;

	default CapabilityComp.DefaultCapabilities.Add(n"IslandFloatotronBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandForceFieldCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BasicAITakeDamageCapability");
}