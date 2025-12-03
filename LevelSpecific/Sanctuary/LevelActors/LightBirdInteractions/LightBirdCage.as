class ALightBirdCage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;
	default FauxPhysicsTranslateComponent.SpringStrength = 0.0;
/*
	UPROPERTY(DefaultComponent)
	USphereComponent LightBirdOverlap;
	default LightBirdOverlap.CollisionProfileName = n"OverlapAllDynamic";
	default LightBirdOverlap.SphereRadius = 50.0;
*/
	UPROPERTY(DefaultComponent)
	ULightBirdTargetComponent LightBirdTargetComponent;
	default LightBirdTargetComponent.AutoAimMaxAngle = 10.0;

	UPROPERTY(DefaultComponent)
	UDarkPortalTargetComponent DarkPortalTargetComponent;
	default DarkPortalTargetComponent.MaximumDistance = 2000.0;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsSpringConstraint FauxPhysicsSpringConstraint;
	default FauxPhysicsSpringConstraint.MaximumForce = 1000.0;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;
	default LightBirdResponseComponent.bExclusiveAttachedIllumination = true;

	UPROPERTY(DefaultComponent)
	ULightBirdChargeComponent LightBirdChargeComponent;	

	UPROPERTY(EditAnywhere)
	TArray<ALightBirdCageSocket> Sockets;

	float InitialSpringStrength;
	float InitialMaximumForce;
	float InitialFriction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialSpringStrength = FauxPhysicsSpringConstraint.SpringStrength;
		InitialMaximumForce = FauxPhysicsSpringConstraint.MaximumForce;
		InitialFriction = FauxPhysicsTranslateComponent.Friction;

		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		DarkPortalResponseComponent.OnReleased.AddUFunction(this, n"OnReleased");
	}

	UFUNCTION()
	private void OnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponenet)
	{
		FauxPhysicsTranslateComponent.Friction = InitialFriction;
		FauxPhysicsSpringConstraint.AddDisabler(Portal);
	}

	UFUNCTION()
	private void OnReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponenet)
	{
		FauxPhysicsSpringConstraint.RemoveDisabler(Portal);				
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Socket : Sockets)
		{
			float Distance = GetDistanceTo(Socket);
			if (Distance <= Socket.SocketMagnetRadius)
			{
				if (!DarkPortalResponseComponent.IsGrabbed())
					FauxPhysicsTranslateComponent.Friction = 8.0;

				FauxPhysicsSpringConstraint.AnchorAttachActor = Socket;
				FauxPhysicsSpringConstraint.SpringStrength = 6000.0;
				FauxPhysicsSpringConstraint.MaximumForce = 6000.0;

				if (Socket.SocketedActor != this)
					Socket.Socket(this);
			}
			else
			{
				if (FauxPhysicsSpringConstraint.AnchorAttachActor == Socket)
				{
					FauxPhysicsSpringConstraint.AnchorAttachActor = nullptr;
					FauxPhysicsSpringConstraint.SpringStrength = InitialSpringStrength;
					FauxPhysicsSpringConstraint.MaximumForce = InitialMaximumForce;
					FauxPhysicsTranslateComponent.Friction = InitialFriction;
				
					if (Socket.SocketedActor == this)
						Socket.Unsocket();
				}
			}
		}

	//	Print("SpringTo: " + FauxPhysicsSpringConstraint.AnchorAttachActor, 0.0, FLinearColor::Green);
	//	Print("MaximumForce: " + FauxPhysicsSpringConstraint.MaximumForce, 0.0, FLinearColor::Green);

	}

}