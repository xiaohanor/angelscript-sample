UCLASS(Abstract)
class AAISkylineSniper : AAISkylineEnforcerBase
{
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSniperBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	USkylineSniperDamageComponent DamageComp;

	UPROPERTY(DefaultComponent)
	USkylineSniperAimingComponent AimingComp;
}