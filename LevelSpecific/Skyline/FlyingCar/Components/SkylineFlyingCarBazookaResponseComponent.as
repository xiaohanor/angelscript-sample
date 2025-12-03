event void FSkylineFlyingCarBazookaOnHit(FVector ImpactPoint, FVector ImpulseDirection);

class USkylineFlyingCarBazookaResponseComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSkylineFlyingCarBazookaOnHit OnHit;
};