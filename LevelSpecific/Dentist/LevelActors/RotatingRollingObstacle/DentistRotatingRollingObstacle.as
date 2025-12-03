UCLASS(Abstract)
class ADentistRotatingRollingObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RollingPivot1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RollingPivot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCapsuleCollisionComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShapeComp;
	
	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY(EditAnywhere)
	float ImpulseStrength = 1000.0;

	UPROPERTY()
	FDentistToothApplyRagdollSettings RagdollSettings;

	UPROPERTY(EditAnywhere)
	float RotateSpeed = 60.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComponent.OnAnyImpactByPlayer.AddUFunction(this, n"HandlePlayerImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetActorRelativeRotation(FRotator(0.0, RotateSpeed * Time::PredictedGlobalCrumbTrailTime, 0.0));
		RollingPivot1.SetRelativeRotation(FRotator(0.0, 0.0, -RotateSpeed * 5 * Time::PredictedGlobalCrumbTrailTime));
		RollingPivot2.SetRelativeRotation(FRotator(0.0, 0.0, RotateSpeed * 5 * Time::PredictedGlobalCrumbTrailTime));
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		FVector ClosestLocation = MoveIntoPlayerShapeComp.Shape.GetClosestPointToPoint(MoveIntoPlayerShapeComp.WorldTransform, Player.ActorCenterLocation);
		FVector DirectionToPlayer = (Player.ActorCenterLocation - ClosestLocation).GetSafeNormal();

		FVector Impulse = DirectionToPlayer * ImpulseStrength;

		if (Impulse.Z < 1000.0)
			Impulse.Z = 1000.0;

		FDentistRotatingRollingObstacleOnLaunchPlayerEventData EventData;
		EventData.Player = Player;
		EventData.ImpulseStrength = Impulse.Size();
		EventData.Impulse = Impulse;
		UDentistRotatingRollingObstacleEventHandler::Trigger_OnLaunchPlayer(this, EventData);

		auto ResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
		if(ResponseComp != nullptr)
		{
			ResponseComp.OnImpulseFromObstacle.Broadcast(this, Impulse, RagdollSettings);
		}

		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback(Player);
	}
};