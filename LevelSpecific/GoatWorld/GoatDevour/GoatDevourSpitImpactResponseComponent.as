event void FGoatDevourSpitLaunchEvent();
event void FGoatDevourSpitImpactEvent(AHazeActor OwningActor, FHitResult HitResult);

class UGoatDevourSpitImpactResponseComponent : UActorComponent
{
	UPROPERTY()
	FGoatDevourSpitLaunchEvent OnLaunch;

	UPROPERTY()
	FGoatDevourSpitImpactEvent OnImpact;

	void Launched()
	{
		OnLaunch.Broadcast();
	}

	void Impact(AHazeActor OwningActor, FHitResult Hit)
	{
		OnImpact.Broadcast(OwningActor, Hit);
	}
}