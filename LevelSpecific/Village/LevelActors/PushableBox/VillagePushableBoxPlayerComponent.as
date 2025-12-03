class UVillagePushableBoxPlayerComponent : UActorComponent
{
	AVillagePushableBox BoxActor;

	bool bPushing = false;
	bool bStruggling = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
}