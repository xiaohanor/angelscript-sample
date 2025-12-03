UCLASS(Abstract)
class AAIIslandAttackShip : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandAttackShipPilotDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandAttackShipNavigateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandAttackShipSwitchWaypointCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandAttackShipCrashCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandAttackShipBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent, Attach="MeshOffsetComponent")
	USceneComponent TempMesh;

	UPROPERTY(DefaultComponent, Attach="TempMesh")
	UStaticMeshComponent CannonMesh;	
	default CannonMesh.RelativeLocation = FVector(337.5, 0.0, -87.5);
	default CannonMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "RightHand")
	UBasicAIProjectileLauncherComponent RocketLauncherComp;

	UPROPERTY(DefaultComponent, Attach="CannonMesh")
	UIslandAttackShipBeamLauncherComponent BeamLauncherComp;

	UPROPERTY(DefaultComponent)
	UIslandAttackShipTrackingLaserComponent TrackingLaserComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Spine")
	UCapsuleComponent HitCapsule;
	default HitCapsule.bGenerateOverlapEvents = false;
	default HitCapsule.CollisionProfileName = n"EnemyIgnoreCharacters";

	UPROPERTY(DefaultComponent, Attach = "HitCapsule")
	UIslandRedBlueTargetableComponent TargetableComp;

	UPROPERTY(DefaultComponent, Attach = "HitCapsule")
	UIslandRedBlueImpactResponseComponent BulletResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(EditInstanceOnly)
	ASplineActor EntrySplineActor;
	
	UHazeSplineComponent EntrySplineComp;
	float DistanceAlongSpline;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;
	
	UPROPERTY(EditAnywhere)
	float EntryTravelDuration = 6.0;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve EntrySpeed;
	default EntrySpeed.AddDefaultKey(0.0, 0.0);
	default EntrySpeed.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve EntryRotation;
	default EntryRotation.AddDefaultKey(0.0, 0.0);
	default EntryRotation.AddDefaultKey(1.0, 1.0);


	bool bHasFinishedEntry = false;

	bool bHasPilotDied = false;

	UPROPERTY(EditAnywhere)
	float BobHeight = 25.0;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 2.0;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0.0;

	UPROPERTY(BlueprintReadOnly)
	AIslandAttackShipManagerActor CurrentManager;

	UPROPERTY(BlueprintReadOnly)
	AIslandAttackShipScenepointActor CurrentWaypoint;

	UFUNCTION(BlueprintEvent)
	void OnPilotDied() {}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(EntrySplineActor != nullptr)
		{
			EntrySplineComp = EntrySplineActor.Spline;
			OnUpdate(1.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// Entry spline is optional
		if (EntrySplineActor != nullptr)
		{
			EntrySplineComp = EntrySplineActor.Spline;
			OnUpdate(0.0);
			MoveAnimation.BindUpdate(this, n"OnUpdate");
			MoveAnimation.BindFinished(this, n"OnFinished");
			MoveAnimation.SetPlayRate(1.0 / EntryTravelDuration);
		}

		ApplyDefaultSettings(IslandAttackShipHealthBarSettings);

		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		if (IslandAttackShip::GetClosestManager(this, CurrentManager))
		{
			CurrentManager.ReportToManager(this);
		}

		if (CurrentManager.HasTeam())
			BobOffset = Math::RandRange(0.1, 3);

		Activate();		
	}


	UFUNCTION()
	private void OnRespawn()
	{
		if (EntrySplineComp != nullptr)
			bHasFinishedEntry = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshOffsetComponent.SetRelativeLocation(FVector::UpVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		DistanceAlongSpline = EntrySplineComp.SplineLength * EntrySpeed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = EntrySplineComp.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(FVector::UpVector, TransformAtDistance.Rotation.ForwardVector), EntryRotation.GetFloatValue(Alpha));
		
		SetActorLocationAndRotation(CurrentLocation, CurrentRotation);
	}

	UFUNCTION()
	void OnFinished()
	{
		bHasFinishedEntry = true;
	}

	UFUNCTION()
	void Activate()
	{
		MoveAnimation.Play();
		//UIslandAttackShipEffectHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		MoveAnimation.Stop();
		//UIslandAttackShipEffectHandler::Trigger_OnStopMoving(this);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetFocusLocation() const
	{
		float Offset = -100.0;
		return MeshOffsetComponent.WorldLocation + FVector::UpVector * Offset;
	}

	// Hack for hiding other static mesh cannon used in the cutscene.
	UFUNCTION(BlueprintEvent)
	void BP_HideCutsceneCannon() {}
}

asset IslandAttackShipHealthBarSettings of UBasicAIHealthBarSettings
{
	HealthBarOffset = FVector(0.0, 0.0, 280.0);
}

class UIslandAttackShipBeamLauncherComponent : UBasicAIProjectileLauncherComponent
{	
}
