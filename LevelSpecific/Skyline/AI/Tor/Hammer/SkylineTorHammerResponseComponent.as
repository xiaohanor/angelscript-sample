event void FSkylineTorHammerResponseComponentHitEvent(float Damage, EDamageType DamageType, AHazeActor Instigator);

class USkylineTorHammerResponseComponent : UActorComponent
{
	FSkylineTorHammerResponseComponentHitEvent OnHit;
}