event void FIslandSplineFollowingPerchDroidSignature();

class AIslandSplineFollowingPerchDroid : ABasicAIFlyingCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"IslandSplineFollowingPerchDroidNavigateCapability");

	UPROPERTY(DefaultComponent)
	USceneComponent BobbingRoot;
	
	UPROPERTY(DefaultComponent, Attach = "BobbingRoot")
	USceneComponent AttachComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;
	
	UPROPERTY(EditAnywhere)
	float TravelDuration = 6.0;

	UPROPERTY(EditAnywhere)
	FVector DestinationUpVector = FVector::UpVector;

	UPROPERTY()
	FIslandSplineFollowingPerchDroidSignature OnReachedDestination;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float BobHeight = 50.0;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 2.0;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0.0;

	bool bHasFinishedEntrance = false;

	UPROPERTY(EditAnywhere)
	bool bActivateOnRiderActorSpawn = true;

	UPROPERTY(EditAnywhere)
	bool bCanFreeRoamChaseTarget = true;

	UPROPERTY(DefaultComponent)
	UHoverPerchComponent HoverPerchComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.SpringStrength = 0.25;

	UPROPERTY(EditInstanceOnly)
	IslandSplineFollowingPerchDroid::EWaypointPicking WaypointPickingMode = IslandSplineFollowingPerchDroid::EWaypointPicking::PickDefault;
	
	UPROPERTY(EditInstanceOnly)
	float MovementCooldownMax = 5.0;

	UPROPERTY(EditInstanceOnly)
	float MovementCooldownMin = 4.0;

	// Get attached child actor
	ABasicAICharacter RiderActor;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			OnUpdate(1.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// Entry spline is optional
		if (SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			OnUpdate(0.0);
			MoveAnimation.BindUpdate(this, n"OnUpdate");
			MoveAnimation.BindFinished(this, n"OnFinished");
			MoveAnimation.SetPlayRate(1.0 / TravelDuration);
		}
		else
		{
			bHasFinishedEntrance = true;
		}

		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		// Get attached AI actor
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		// Attached actor can be other things than a spawner. Find the spawner.
		for (AActor AttachedActor : AttachedActors)		
		{
			AHazeActorSpawnerBase Spawner = Cast<AHazeActorSpawnerBase>(AttachedActor);
			if (Spawner != nullptr)
			{
				Spawner.OnPostSpawn.AddUFunction(this, n"OnSpawnerSpawned");
				break;
			}
		}
	}

	UFUNCTION()
	private void OnSpawnerSpawned(AHazeActor SpawnedActor)
	{
		RiderActor = Cast<ABasicAICharacter>(SpawnedActor);
		RiderActor.AttachToComponent(AttachComp);
		if (bActivateOnRiderActorSpawn)
			Activate();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		if (Spline != nullptr)
			bHasFinishedEntrance = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BobbingRoot.SetRelativeLocation(FVector::UpVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));
		
		SetActorLocationAndRotation(CurrentLocation, CurrentRotation);
	}

	UFUNCTION()
	void OnFinished()
	{
		OnReachedDestination.Broadcast();
		bHasFinishedEntrance = true;
	}

	UFUNCTION()
	void Activate()
	{
		MoveAnimation.Play();
		UIslandSplineFollowingPerchDroidEffectHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		MoveAnimation.Stop();
		UIslandSplineFollowingPerchDroidEffectHandler::Trigger_OnStopMoving(this);
	}

}

UCLASS(Abstract)
class UIslandSplineFollowingPerchDroidEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}
}

namespace IslandSplineFollowingPerchDroid
{
	enum EWaypointPicking
	{
		PickDefault, 			// Tries to find a waypoint that is not too close from current location, not already held by the Actor, and with clear sightline to target.
		PickClosestToTarget,	// Tries to find a waypoint closest to the target. Require sightline from and to waypoint.
	}
}
