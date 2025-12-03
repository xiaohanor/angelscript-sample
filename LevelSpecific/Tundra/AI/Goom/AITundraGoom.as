UCLASS(Abstract, meta = (DefaultActorLabel = "TundraGoom"))
class ATundraGoom : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGoomBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGoomDamageCapability");
}