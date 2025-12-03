event void FEnforcerArmHitSignature(UEnforcerArmComponent Arm);

class UEnforcerArmResponseComponent : UActorComponent
{
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FEnforcerArmHitSignature OnHit;
}