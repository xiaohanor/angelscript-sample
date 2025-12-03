event void FWingsuitBossShootAtTargetResponseEvent();

class UWingsuitBossShootAtTargetResponseComponent : UActorComponent
{
	UPROPERTY()
	FWingsuitBossShootAtTargetResponseEvent OnImpact;
}