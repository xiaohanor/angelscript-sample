class ASanctuaryLightWormScale : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WormPivot;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;


	UPROPERTY(EditInstanceOnly)
	ASanctuaryLightWormScale CounterActor;

	bool bIsGrabbed = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"HandleReleased");
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bIsGrabbed = true;
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bIsGrabbed = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		WormPivot.WorldRotation = (WormPivot.WorldLocation - TranslateComp.WorldLocation).Rotation();

		if (bIsGrabbed)
		{
			CounterActor.TranslateComp.ApplyForce(CounterActor.ActorLocation, FVector::UpVector * DarkPortalResponseComp.PullForce);
		}
	}
};