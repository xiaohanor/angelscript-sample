event void SkylinEnforcerGravityWhipImpactSignature();
class USkylineEnforcerGravityWhipComponent : UActorComponent
{
	SkylinEnforcerGravityWhipImpactSignature OnImpact;
	FVector ImpactNormal;
	FVector ImpactLocation;
}