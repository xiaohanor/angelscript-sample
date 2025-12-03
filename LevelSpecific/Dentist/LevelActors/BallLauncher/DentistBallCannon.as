UCLASS(Abstract)
class ADentistBallCannon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CannonRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ExplosionVFXComp;

	UPROPERTY()
	FHazeTimeLike ShootTimeLike;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditInstanceOnly)
	TArray<ADentistLaunchedBall> LaunchedBalls;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto LaunchedBall : LaunchedBalls)
		{
			LaunchedBall.OnStartMoving.AddUFunction(this, n"Shoot");
		}
		
		ShootTimeLike.BindUpdate(this, n"ShootTimeLikeUpdate");
	}

	UFUNCTION()
	private void ShootTimeLikeUpdate(float CurrentValue)
	{
		CannonRoot.SetRelativeScale3D(FVector(CurrentValue, 1 / CurrentValue, 1 / CurrentValue));	
	}

	UFUNCTION()
	void Shoot()
	{
		ShootTimeLike.PlayFromStart();
		ExplosionVFXComp.Activate(true);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		FDentistBallCannonOnShootEventData EventData;
		EventData.Location = ExplosionVFXComp.WorldLocation;
		UDentistBallCannonEventHandler::Trigger_OnShoot(this, EventData);
	}
};