event void FEnforcerRocketLauncherResponseComponentHitEvent(float Damage, EDamageType DamageType, AHazeActor Instigator);

class UEnforcerRocketLauncherResponseComponent : UActorComponent
{
	FEnforcerRocketLauncherResponseComponentHitEvent OnHit;
}