UCLASS(Abstract)
class UTundra_River_PlayerSnowballComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionFeatureBase SnowballFeature;

	UPROPERTY()
	TSubclassOf<UCrosshairWidget> CrosshairClass;

	ATundra_River_Snowball Snowball;
	int SnowBallID = 0;
	bool bIsThrowing = false;

	void Throw()
	{
		Snowball.DetachFromActor();

		UTundra_River_SnowballEventHandler::Trigger_OnSnowballThrow(Snowball, FSnowBallEventData(Snowball.OwningPlayer));
		Snowball = nullptr;
		bIsThrowing = false;
	}

	void Cancel()
	{
		if(Snowball != nullptr)
			Snowball.DestroyActor();

		Snowball = nullptr;
	}
};