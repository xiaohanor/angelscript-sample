class ASolarFlareReactionObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisRot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ImpactLocationComp;

	UPROPERTY(DefaultComponent, Attach = AxisRot, ShowOnActor, Category = "Mesh")
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere, Category = "Actor Setup")
	ASolarFlareWaveImpactEventActor ImpactActor;

	UPROPERTY(EditAnywhere, Category = "Actor Setup")
	float ImpactForce = 450.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactActor.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	private void OnImpact()
	{
		AxisRot.ApplyImpulse(ImpactLocationComp.WorldLocation, ActorForwardVector * ImpactForce);
	}
};