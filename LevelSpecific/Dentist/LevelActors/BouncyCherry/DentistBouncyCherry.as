UCLASS(Abstract)
class ADentistBouncyCherry : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY(DefaultComponent)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShapeComp;

	UPROPERTY(DefaultComponent)
	UDentistLaunchedBallImpactResponseComponent LaunchedBallImpactResponseComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY()
	FHazeTimeLike ScaleTimeLike;

	UPROPERTY(EditInstanceOnly)
	AActor SpinningCakeCenterActor;

	UPROPERTY(EditInstanceOnly)
	float DegreesBetweenHoles = 30.0;

	UPROPERTY(EditInstanceOnly)
	float InTunnelRollDegrees = -70.0;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditAnywhere)
	float Force = 1000.0;

	UPROPERTY(EditAnywhere)
	float MinZForce = 400.0;

	FHazeAcceleratedQuat AccCherryQuat;
	FQuat InTunnelQuat;
	FQuat NotInTunnelQuat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScaleTimeLike.BindUpdate(this, n"ScaleTimeLikeUpdate");
		MovementImpactCallbackComponent.OnAnyImpactByPlayer.AddUFunction(this, n"HandlePlayerImpact");
		LaunchedBallImpactResponseComp.OnImpact.AddUFunction(this, n"OnLaunchedBallImpact");

		if (SpinningCakeCenterActor != nullptr)
		{
			FRotator RandomRotation = FRotator(0.0, Math::RandRange(0.0, 360.0), 0.0);
			NotInTunnelQuat = MeshRoot.WorldTransform.InverseTransformRotation(RandomRotation.Quaternion());

			FVector ToCenterDirection = (ActorLocation - SpinningCakeCenterActor.ActorLocation)
			.VectorPlaneProject(FVector::UpVector)
			.GetSafeNormal();
			FQuat AddedQuat = FQuat(ToCenterDirection, Math::DegreesToRadians(InTunnelRollDegrees));
			FQuat ModifiedQuat = FQuat::ApplyDelta(RandomRotation.Quaternion(), AddedQuat);
			InTunnelQuat = MeshRoot.WorldTransform.InverseTransformRotation(ModifiedQuat);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SpinningCakeCenterActor == nullptr)
			return;
		
		FVector ToCenterDirection = (ActorLocation - SpinningCakeCenterActor.ActorLocation)
			.VectorPlaneProject(FVector::UpVector)
			.GetSafeNormal();

		if (ToCenterDirection.GetAngleDegreesTo(SpinningCakeCenterActor.ActorForwardVector) < DegreesBetweenHoles * 0.5)
			AccCherryQuat.SpringTo(NotInTunnelQuat, 20.0, 0.4, DeltaSeconds);
		else
			AccCherryQuat.SpringTo(InTunnelQuat, 15.0, 0.8, DeltaSeconds);

		MeshRoot.SetRelativeRotation(AccCherryQuat.Value);
	}

	UFUNCTION()
	private void ScaleTimeLikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeScale3D(FVector(CurrentValue));
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		FVector AwayDirection = (Player.ActorLocation - ActorLocation).GetSafeNormal();

		FVector Impulse = (AwayDirection * Force);

		if(Impulse.Z < MinZForce)
			Impulse.Z = MinZForce;

		Player.AddMovementImpulse(Impulse);
		ScaleTimeLike.PlayFromStart();
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(Player);

		FDentistBouncyCherryOnBouncePlayerEventData EventData;
		EventData.Player = Player;
		UDentistBouncyCherryEventHandler::Trigger_OnBouncePlayer(this, EventData);
	}

	UFUNCTION()
	private void OnLaunchedBallImpact(ADentistLaunchedBall LaunchedBall, FDentistLaunchedBallImpact Impact, bool bIsFirstImpact)
	{
		ScaleTimeLike.PlayFromStart();

		FDentistBouncyCherryOnBounceLaunchedBallEventData EventData;
		EventData.LaunchedBall = LaunchedBall;
		UDentistBouncyCherryEventHandler::Trigger_OnBounceLaunchedBall(this, EventData);
	}
};