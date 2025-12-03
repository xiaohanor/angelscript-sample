struct FObjectData
{
	UPROPERTY()
	UStaticMesh ObjectMesh;

	UPROPERTY()
	UMaterialInstance ObjectMaterial;

	UPROPERTY()
	FVector AttachOffset;
}

UCLASS(Abstract)
class AIslandFactorySplinePerch : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPerchPointComponent PerchComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisRotate;

	UPROPERTY(DefaultComponent, Attach = AxisRotate)
	USceneComponent ObjectRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PerchMesh;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	USceneComponent ObjectAttachLocation;

	UPROPERTY(DefaultComponent, Attach = ObjectAttachLocation)
	UStaticMeshComponent ObjectMesh;

	UPROPERTY(DefaultComponent, Attach = AxisRotate)
	UFauxPhysicsWeightComponent WeightComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(EditDefaultsOnly)
	TArray<FObjectData> PerchObjects;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AIslandFactoryPerchObject> FallingObject;

	AIslandFactoryPerchLoopingSpline LoopingSpline;
	bool bClampsOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartPerching");
		PerchComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStopPerching");

		SetRandomMesh();
	}

	UFUNCTION()
	void Initialize()
	{
		LoopingSpline.OnStartMoving.AddUFunction(this, n"OnStartMoving");
		LoopingSpline.OnStopMoving.AddUFunction(this, n"OnStopMoving");
	}

	UFUNCTION()
	private void OnStopMoving()
	{
		// PerchComp.Enable(this);
		// PerchComp.bAllowPerch = true;
	}

	UFUNCTION()
	private void OnStartMoving()
	{
		// PerchComp.Disable(this);
		// PerchComp.bAllowPerch = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		AxisRotate.ResetForces();
		WeightComp.ResetInternalState();
		AxisRotate.ResetInternalState();
		ObjectMesh.SetHiddenInGame(false);
		BP_ResetClamps();
		bClampsOpen = false;
		// PerchComp.bAllowPerch = true;
		// PerchMesh.SetHiddenInGame(false);
	}

	UFUNCTION()
	private void OnPlayerStartPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PerchReaction(Player);
	}

	UFUNCTION()
	private void OnPlayerStopPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		// PerchComp.bAllowPerch = false;
		// PerchMesh.SetHiddenInGame(true);
	}

	void PerchReaction(AHazePlayerCharacter Player)
	{
		if(bClampsOpen)
			return;
		
		ObjectMesh.SetHiddenInGame(true);
		AIslandFactoryPerchObject FallingActor = SpawnActor(FallingObject, ObjectMesh.WorldLocation, ObjectMesh.WorldRotation);
		FallingActor.MeshComp.StaticMesh = ObjectMesh.StaticMesh;
		FallingActor.MeshComp.SetMaterial(0, ObjectMesh.GetMaterial(0));
		FallingActor.StartDestroyTimer();
		// Cast<AIslandFactoryPerchObject>(FallingActor).MeshComp.StaticMesh = ObjectMesh.StaticMesh;
		BP_OpenClamps();
		bClampsOpen = true;
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback(Player);
	}

	void SetRandomMesh()
	{
		int RandomInt = Math::RandRange(0, PerchObjects.Num() - 1);
		ObjectMesh.StaticMesh = PerchObjects[RandomInt].ObjectMesh;
		ObjectMesh.SetMaterial(0, PerchObjects[RandomInt].ObjectMaterial);
		ObjectMesh.SetWorldLocation(ObjectAttachLocation.WorldLocation - (ObjectMesh.BoundsOrigin - ObjectMesh.WorldLocation));
		ObjectMesh.AddLocalOffset(PerchObjects[RandomInt].AttachOffset);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenClamps(){};

	UFUNCTION(BlueprintEvent)
	void BP_ResetClamps(){};
};