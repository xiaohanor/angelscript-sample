UCLASS(Abstract)
class USplitTraversalAutomaticDoorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartOpening() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopOpening() {}
}

class ASplitTraversalAutomaticDoor : AWorldLinkDoubleActor
{

	default ActorTickEnabled = false;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UFauxPhysicsTranslateComponent DoorLeftScifiTranslateComp;
	UPROPERTY(DefaultComponent, Attach = DoorLeftScifiTranslateComp)
	UFauxPhysicsForceComponent LeftForceComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UFauxPhysicsTranslateComponent DoorRightScifiTranslateComp;
	UPROPERTY(DefaultComponent, Attach = DoorRightScifiTranslateComp)
	UFauxPhysicsForceComponent RightForceComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent DoorLeftFantasyRoot;
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent DoorRightFantasyRoot;

	UPROPERTY(EditInstanceOnly)
	AHazeSphere HazeSphereActor;

	UPROPERTY(EditAnywhere)
	FLinearColor ActivatedHazeSphereColor;

	UPROPERTY(EditInstanceOnly)
	AHazeSpotLight SpotLightActor;

	UPROPERTY(EditAnywhere)
	FLinearColor ActivatedSpotLightColor;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor LightPropActor;

	UPROPERTY(EditAnywhere)
	UMaterialInstance ActivatedLightMaterial;

	UPROPERTY(EditAnywhere)
	int MaterialSlot = 1;

	UPROPERTY(EditAnywhere)
	float TriggerRadius = 600.0;

	UPROPERTY(EditAnywhere)
	float DoorForce = 200.0;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalBranchLever Lever;

	float CurrentPosition;

	bool bMioInRange = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Lever.OnReachedEnd.AddUFunction(this, n"OpenDoor");
		DoorRightScifiTranslateComp.OnConstraintHit.AddUFunction(this, n"ConstraintHit");
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OpenDoor()
	{
		bMioInRange = true;
		BP_SetMioInRange(true);
		RightForceComp.Force = FVector::ForwardVector * DoorForce;
		LeftForceComp.Force = FVector::ForwardVector * DoorForce;

		HazeSphereActor.HazeSphereComponent.SetColor(
			HazeSphereActor.HazeSphereComponent.Opacity,
			HazeSphereActor.HazeSphereComponent.Softness,
			ActivatedHazeSphereColor
		);

		SpotLightActor.SpotLightComponent.SetLightColor(ActivatedSpotLightColor);

		LightPropActor.StaticMeshComponent.SetMaterial(MaterialSlot, ActivatedLightMaterial);

		SetActorTickEnabled(true);

		BP_OpenDoor();

		USplitTraversalAutomaticDoorEventHandler::Trigger_OnStartOpening(this);
	}

	UFUNCTION()
	private void ConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		USplitTraversalAutomaticDoorEventHandler::Trigger_OnStopOpening(this);
		Timer::SetTimer(this,n"StopTickTimer",1,false);
	}

	UFUNCTION()
	private void StopTickTimer()
	{
		//SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DoorLeftFantasyRoot.SetRelativeLocation(FVector(DoorLeftScifiTranslateComp.RelativeLocation) * 1.2);
		DoorRightFantasyRoot.SetRelativeLocation(FVector(DoorRightScifiTranslateComp.RelativeLocation) * 1.2);
		Print("Open!");
	}

	UFUNCTION(BlueprintEvent)
	void BP_SetMioInRange(bool bInRange)
	{}

	UFUNCTION(BlueprintEvent)
	private void BP_OpenDoor(){}
};