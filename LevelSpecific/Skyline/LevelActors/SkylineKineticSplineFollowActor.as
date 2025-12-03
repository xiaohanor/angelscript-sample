UCLASS(Abstract)
class USkylineKineticSplineFollowActorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitTop()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitBottom()
	{
	}	
};

class ASkylineKineticSplineFollowActor : AKineticSplineFollowActor
{
	bool bHitTop = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnReachedEnd.AddUFunction(this, n"HandleReachedEnd");
	}

	UFUNCTION()
	private void HandleReachedEnd()
	{
		PrintToScreenScaled("Reached End", 2.0);
		if (bHitTop)
			USkylineKineticSplineFollowActorEventHandler::Trigger_OnHitTop(this);
		else
			USkylineKineticSplineFollowActorEventHandler::Trigger_OnHitBottom(this);

		bHitTop = !bHitTop;

		PauseMovement(this);

		Timer::SetTimer(this, n"EnableTick", 1.5);
	}

	UFUNCTION()
	private void EnableTick()
	{
		UnpauseMovement(this);
	}
};