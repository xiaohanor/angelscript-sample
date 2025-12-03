event void FSkylineTorDebrisResponseComponentHitEvent(float Damage, EDamageType DamageType, AHazeActor Instigator);

class USkylineTorDebrisResponseComponent : UActorComponent
{
	FSkylineTorDebrisResponseComponentHitEvent OnHit;
}