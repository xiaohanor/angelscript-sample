struct FSummitFireBreathHitParams
{

}

event void FSummitFireBreathOnHit(FSummitFireBreathHitParams Params);

class USummitFireBreathResponseComponent : UActorComponent
{
	UPROPERTY()
	FSummitFireBreathOnHit OnHit;
};