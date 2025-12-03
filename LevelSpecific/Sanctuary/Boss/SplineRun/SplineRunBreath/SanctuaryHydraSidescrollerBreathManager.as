event void FSanctuaryHydraActivateSidescrollerBreathSignature(bool bActive);
class ASanctuaryHydraSidescrollerBreathManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;
	
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditAnywhere)
	AActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	EHazePlayer TargetPlayer;
	AHazePlayerCharacter Player;

	UPROPERTY()
	FSanctuaryHydraActivateSidescrollerBreathSignature SetActive;

	FHazeAcceleratedFloat AccSplineProgress;
	float ProgressAlongSpline;

	float FollowDuration = 6.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::GetPlayer(TargetPlayer);
		SplineComp = UHazeSplineComponent::Get(SplineActor);

		DevToggleHydraPrototype::SideScrollerVerticalBreath.MakeVisible();

		QueueComp.SetLooping(true);
		QueueComp.Idle(5.0);
		QueueComp.Event(this, n"Activate");
		QueueComp.Idle(8.0);
		QueueComp.Event(this, n"Deactivate");
	}

	UFUNCTION()
	private void Activate()
	{
		AccSplineProgress.SnapTo(ProgressAlongSpline);
		SetActive.Broadcast(true);
	}

	UFUNCTION()
	private void Deactivate()
	{
		SetActive.Broadcast(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ProgressAlongSpline = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		AccSplineProgress.AccelerateTo(ProgressAlongSpline, FollowDuration, DeltaSeconds);

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AccSplineProgress.Value);
		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(AccSplineProgress.Value);

		SetActorLocationAndRotation(Location, Rotation);
	}
};