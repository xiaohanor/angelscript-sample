class ASkylineHighwayDraggableCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineHighwayDraggableCoverMovementCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bAllowUsingBoxCollisionShape = true;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::Drag;
	default WhipResponseComp.bAllowMultiGrab = false;
	default WhipResponseComp.OffsetDistance = 750;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent, Attach = WhipTarget)
	UTargetableOutlineComponent WhipOutline;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComp)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USkylineHighwayDraggableCoverComponent DraggableComp;

	UPROPERTY(EditInstanceOnly)
	TArray<ASplineActor> BoundsSplines;

	AHazeActor Grabber;
	UCameraPointOfInterestClamped POI;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		WhipResponseComp.OnGrabbed.AddUFunction(this, n"Grabbed");
		WhipResponseComp.OnReleased.AddUFunction(this, n"Released");
		MoveComp.ApplySplineCollision(BoundsSplines, this);
	}

	UFUNCTION()
	private void OnReset()
	{
		DraggableComp.bGrabbed = false;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(DraggableComp.bGrabbed)
		{
			DraggableComp.MoveTowards(WhipResponseComp.DesiredLocation, 1000);
		}
		else
			DraggableComp.bHasTargetLocation = false;
	}

	UFUNCTION()
	private void Released(UGravityWhipUserComponent UserComponent,
	                      UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		DraggableComp.bGrabbed = false;
		if(DraggableComp.Grabber != nullptr)
			UCameraSettings::GetSettings(Cast<AHazePlayerCharacter>(DraggableComp.Grabber)).IdealDistance.Clear(this);
		if(POI != nullptr)
			POI.Clear();
	}

	UFUNCTION()
	private void Grabbed(UGravityWhipUserComponent UserComponent,
	                     UGravityWhipTargetComponent TargetComponent,
	                     TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		DraggableComp.bGrabbed = true;
		DraggableComp.Grabber = Cast<AHazeActor>(UserComponent.Owner);
		UCameraSettings::GetSettings(Cast<AHazePlayerCharacter>(DraggableComp.Grabber)).IdealDistance.ApplyAsAdditive(500, this, 0.5);

		if(POI != nullptr)
			POI.Clear();
		POI = Cast<AHazePlayerCharacter>(DraggableComp.Grabber).CreatePointOfInterestClamped();
		POI.FocusTarget.SetFocusToActor(this);
		POI.Apply(this, 1.5, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	FVector GetActorCenterLocation() const
	{
		return Mesh.WorldLocation;
	}
}