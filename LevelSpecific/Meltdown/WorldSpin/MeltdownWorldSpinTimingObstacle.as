class AMeltdownWorldSpinTimingObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Obstacle;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Idle;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDeathTriggerComponent DeathTrigger;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Pipe;

	UPROPERTY(EditAnywhere)
	bool bManualStart;

	UPROPERTY(EditAnywhere)
	float ActiveTime;

	UPROPERTY(EditAnywhere)
	float DownTime;

	UPROPERTY(EditAnywhere)
	float StartDelay;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ThrusterFF;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void StartPipeFire()
	{
		UMeltdownWorldSpinTimingObstacleEventHandler::Trigger_StartFire(this);
	}

	UFUNCTION()
	void StopPipeFire()
	{
		UMeltdownWorldSpinTimingObstacleEventHandler::Trigger_StopFire(this);
	}

};

UCLASS(Abstract)
class UMeltdownWorldSpinTimingObstacleEventHandler : UHazeEffectEventHandler
{
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFire() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFire() {}

};