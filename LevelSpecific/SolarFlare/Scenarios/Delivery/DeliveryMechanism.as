class ADeliveryMechanism : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"DeliveryRotationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"DeliverySplineMoveCapability");

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 10.0;

	AHazeActor TargetRotatorActor;

	bool bStartSplineMove;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = SplineActor.Spline;
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		TargetRotatorActor = this;
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		bStartSplineMove = true;
	}

	void SetDeliveryRotation(AHazeActor Actor)
	{

	}
}