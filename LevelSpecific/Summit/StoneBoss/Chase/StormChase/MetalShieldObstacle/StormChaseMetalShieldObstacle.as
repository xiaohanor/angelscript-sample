event void FOnStormChaseMetalShieldStartedMoving();
event void FOnStormChaseMetalShieldFinishedMoving();
event void FOnStormChaseMetalShieldHitByAcid();
UCLASS(Abstract)
class AStormChaseMetalShieldObstacle : AHazeActor
{
	UPROPERTY()
	FOnStormChaseMetalVineMelted OnStormChaseMetalVineMelted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PreviewMesh;
	default PreviewMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default PreviewMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonAcidAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(EditInstanceOnly)
	bool bStartInTargetLocation = false;

	UPROPERTY(EditInstanceOnly)
	bool bShouldRotateMovement = true;

	UPROPERTY(EditInstanceOnly)
	ASerpentEventActivator SerpentEventActivator;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget))
	FVector TargetLocationOffset;

	UPROPERTY(EditInstanceOnly)
	float MoveDuration = 1.75;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveAlphaCurve;

	UPROPERTY()
	FOnStormChaseMetalShieldStartedMoving OnStartedMoving;

	UPROPERTY()
	FOnStormChaseMetalShieldFinishedMoving OnFinishedMoving;

	UPROPERTY()
	FOnStormChaseMetalShieldHitByAcid OnHitByAcid;
	float RotationAmount = 180.0;

	bool bHasBeenActivated;
	FVector TargetLocation;
	FRotator TargetRotation;
	FVector StartLocation;
	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AutoAimComp.TargetShape.SphereRadius *= ActorScale3D.GetMax();

		if (PreviewMesh.RelativeLocation.Y > 0.0)
			PreviewMesh.RelativeRotation +=  FRotator(0.0, 0.0, RotationAmount);
		else
			PreviewMesh.RelativeRotation +=  FRotator(0.0, 0.0, -RotationAmount);
		
		//Adjusted so that instead we see its end location first
		StartLocation = PreviewMesh.WorldLocation;
		StartRotation = PreviewMesh.WorldRotation;
		TargetLocation = ActorLocation;
		TargetRotation = ActorRotation;
		SetActorLocationAndRotation(StartLocation, StartRotation);

		if (bStartInTargetLocation)
		{
			SetActorLocationAndRotation(TargetLocation, TargetRotation);
		}
		else if (SerpentEventActivator != nullptr)
		{
			SerpentEventActivator.OnSerpentEventTriggered.AddUFunction(this, n"StartMovingToTarget");
		}

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit AcidHit)
	{
		FStormChaseMetalShieldHitByAcidParams Params;
		Params.ImpactLocation = AcidHit.ImpactLocation;
		UStormChaseMetalShieldObstacleEventHandler::Trigger_OnHitByAcidProjectile(this, Params);
		AddActorDisable(this);
	}

	UFUNCTION()
	void StartMovingToTarget()
	{
		if(bStartInTargetLocation)
			return;

		ActionQueueComp.Duration(MoveDuration, this, n"MoveToTarget");
		ActionQueueComp.Event(this, n"FinishedMoving");
		UStormChaseMetalShieldObstacleEventHandler::Trigger_OnStartMoving(this);
		OnStartedMoving.Broadcast();
	}

	UFUNCTION()
	private void FinishedMoving()
	{
		UStormChaseMetalShieldObstacleEventHandler::Trigger_OnFinishMoving(this);
		OnFinishedMoving.Broadcast();
	}

	UFUNCTION()
	private void MoveToTarget(float LinearAlpha)
	{
		float MoveAlpha = MoveAlphaCurve.GetFloatValue(LinearAlpha);
		FVector NewLocation = Math::Lerp(StartLocation, TargetLocation, MoveAlpha);
		FRotator NewRotation = Math::LerpShortestPath(StartRotation, TargetRotation, MoveAlpha);
		if (bShouldRotateMovement)
			SetActorLocationAndRotation(NewLocation, NewRotation);
		else	
			SetActorLocation(NewLocation);
	}
};