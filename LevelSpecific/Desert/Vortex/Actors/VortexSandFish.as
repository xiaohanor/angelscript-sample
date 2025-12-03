UCLASS(Abstract)
class AVortexSandFish : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	USteerSandFishInteractionComponent LeftInteraction;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	USteerSandFishInteractionComponent RightInteraction;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UBoxComponent HeadCollider;

	UPROPERTY(DefaultComponent)
	protected UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	protected UClimbSandFishFollowComponent FollowComp;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UVortexSandFishGlassShardsComponent GlassShardsComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::High;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLogComp;
#endif

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSplineActor;
	UHazeSplineComponent TargetSplineComp;

	UPROPERTY(EditAnywhere)
	bool bActiveFromStart = true;

	UPROPERTY(EditAnywhere)
	bool bLooping = false;

	UPROPERTY(EditAnywhere)
	float CurrentDistanceAlongSpline = 0.0;

	UPROPERTY(EditAnywhere)
	float MovementSpeed = 1000.0;

	// Vortex
	bool bVortexMovementActive;
	bool bVortexFollowSpline = true;
	FRotator CurRot;

	// Climbing
	bool bIsClimbing;
	float ClimbDistanceAlongSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor ClimbSpline;

	UPROPERTY(EditInstanceOnly)
	AGrapplePoint ClimbGrapplePoint;

	// Steer
	bool bIsSteered;
	float SteerDistanceAlongSpline;
	float Steering;
	FHazeAcceleratedFloat AccSteering;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SteerSpline;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor SteerCamera;

	// Fall
	bool bIsFalling;
	float FallDistanceAlongSpline;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FallSpline;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UBillboardComponent MioFallLocation;
	
	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UBillboardComponent ZoeFallLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Desert::GetManager().VortexSandfish = this;

		if(TargetSplineActor != nullptr)
			TargetSplineComp = TargetSplineActor.Spline;

		if (bActiveFromStart)
			bVortexMovementActive = true;

		FInteractionCondition InteractionCondition;
		InteractionCondition.BindUFunction(this, n"InteractionCondition");
		LeftInteraction.AddInteractionCondition(this, InteractionCondition);
		RightInteraction.AddInteractionCondition(this, InteractionCondition);
	}

	UFUNCTION()
	private EInteractionConditionResult InteractionCondition(const UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		switch(Desert::GetDesertLevelState())
		{
			case EDesertLevelState::Climb:
				return EInteractionConditionResult::Enabled;

			default:
				return EInteractionConditionResult::Disabled;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Desert::GetManager().VortexSandfish = nullptr;
	}

	UFUNCTION(BlueprintCallable)	
	void Stop()
	{
		bVortexMovementActive = false;
	}

	UFUNCTION(BlueprintCallable)
	void Start()
	{
		bVortexMovementActive = true;
	}

	UFUNCTION(BlueprintCallable)
	void NextSpline(ASplineActor NewSpline ,bool bLoop, bool bSnapToSpline = true, float Speed = 1000)
	{
		bLooping = bLoop;
		MovementSpeed = Speed;
		
		TargetSplineActor = NewSpline;
		TargetSplineComp = TargetSplineActor.Spline;
		
		CurrentDistanceAlongSpline = 0;
		bVortexFollowSpline = bSnapToSpline;
	}

	UFUNCTION(CallInEditor)
	void SnapToSpline()
	{
		if (TargetSplineActor == nullptr)
			return;

		UHazeSplineComponent SplineComp = UHazeSplineComponent::Get(TargetSplineActor);
		if (SplineComp != nullptr)
		{
			const auto SplineTransform = SplineComp.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
			SetActorLocationAndRotation(SplineTransform.Location, SplineTransform.Rotation);
		}
	}
}