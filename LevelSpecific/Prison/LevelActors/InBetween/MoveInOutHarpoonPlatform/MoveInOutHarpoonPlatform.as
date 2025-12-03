UCLASS(Abstract)
class AMoveInOutHarpoonPlatform : AKineticMovingActor
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnStartForward.AddUFunction(this, n"OnStartForward");
		OnReachedForward.AddUFunction(this, n"OnReachedForward");
		OnStartBackward.AddUFunction(this, n"OnStartBackward");
		OnReachedBackward.AddUFunction(this, n"OnReachedBackward");
	}

	UFUNCTION()
	private void OnStartForward()
	{
		UMoveInOutHarpoonPlatformEventHandler::Trigger_StartMovingOut(this);
	}

	UFUNCTION()
	private void OnReachedForward()
	{
		UMoveInOutHarpoonPlatformEventHandler::Trigger_StopAtOutLocation(this);
	}

	UFUNCTION()
	private void OnStartBackward()
	{
		UMoveInOutHarpoonPlatformEventHandler::Trigger_StartMovingIn(this);
	}

	UFUNCTION()
	private void OnReachedBackward()
	{
		UMoveInOutHarpoonPlatformEventHandler::Trigger_StopAtInLocation(this);
	}
};