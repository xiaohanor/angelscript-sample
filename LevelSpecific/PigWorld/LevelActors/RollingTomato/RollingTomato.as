UCLASS(Abstract)
class ARollingTomato : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TomatoRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;

	UPROPERTY(EditInstanceOnly)
	AHazeActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float RollSpeed = 800.0;

	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float SplineStartFraction = 0.0;

	UPROPERTY(EditAnywhere)
	bool bPreviewPosition = false;

	float SplineDist = 0.0;

	bool bSmashed = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewPosition && SplineActor != nullptr)
		{
			UHazeSplineComponent Spline = UHazeSplineComponent::Get(SplineActor);
			if (Spline == nullptr)
				return;

			FTransform PreviewTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength * SplineStartFraction);
			FRotator Rot = FRotator(PreviewTransform.Rotation);
			Rot.Pitch = Math::Clamp(Rot.Pitch, -8.0, 8.0);
			SetActorLocationAndRotation(PreviewTransform.Location, Rot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(SplineActor);

		SetActorLocation(SplineComp.GetWorldLocationAtSplineFraction(SplineStartFraction));
		SplineDist = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnterTrigger");
	}

	UFUNCTION()
	private void PlayerEnterTrigger(AHazePlayerCharacter Player)
	{
		Smash(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SplineDist += RollSpeed * DeltaTime;
		SetActorLocationAndRotation(SplineComp.GetWorldLocationAtSplineDistance(SplineDist), SplineComp.GetWorldRotationAtSplineDistance(SplineDist));
		if (SplineDist >= SplineComp.SplineLength)
			SplineDist = 0.0;

		TomatoRoot.AddLocalRotation(FRotator(-500.0 * DeltaTime, 0.0, 0.0));
	}

	void Smash(AHazePlayerCharacter Player)
	{
		bSmashed = true;
		BP_Smash();

		FTomatoHitEventHandlerParams EventParams;
		EventParams.Player = Player;
		URollingTomatoEventHandler::Trigger_TomatoHit(this, EventParams);

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Smash()
	{

	}
}