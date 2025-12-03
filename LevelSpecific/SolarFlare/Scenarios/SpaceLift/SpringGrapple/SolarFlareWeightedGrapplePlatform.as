class ASolarFlareWeightedGrapplePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsSpringConstraint SpringConstraint;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareWeightedGrapplePlatformCapability");

	UPROPERTY(EditAnywhere)
	AGrapplePoint Grapple1;

	UPROPERTY(EditAnywhere)
	AGrapplePoint Grapple2;

	float TargetSpeed;
	float StartForceAmount = 0.0;
	float TargetAddAmount = -1500.0;
	float DelayDuration = 1.0;
	float DelayTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Grapple1.AttachToComponent(TranslateComp, NAME_None, EAttachmentRule::KeepWorld);
		Grapple2.AttachToComponent(TranslateComp, NAME_None, EAttachmentRule::KeepWorld);

		Grapple1.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPointEvent");
		Grapple2.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPointEvent");
	}

	UFUNCTION()
	private void OnPlayerInitiatedGrappleToPointEvent(AHazePlayerCharacter Player,
	                                                  UGrapplePointBaseComponent GrapplePoint)
	{
		if (TargetSpeed < 0.0)
			TargetSpeed = 0.0;

		TargetSpeed += TargetAddAmount;
		DelayTime = Time::GameTimeSeconds + DelayDuration;
	}
}