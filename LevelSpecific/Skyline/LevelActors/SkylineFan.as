class ASkylineFan : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;
	default Collision.CollisionEnabled = ECollisionEnabled::QueryOnly;

	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent FauxPhysicsAxisRotateComponent;
	default FauxPhysicsAxisRotateComponent.LocalRotationAxis = FVector::ForwardVector;
	default FauxPhysicsAxisRotateComponent.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsAxisRotateComponent)
	UFauxPhysicsForceComponent FauxPhysicsForceComponent;
	default FauxPhysicsForceComponent.bWorldSpace = false;
	default FauxPhysicsForceComponent.Force = FVector::UpVector * 5000.0;
	default FauxPhysicsForceComponent.RelativeLocation = FVector::RightVector * 200.0;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Drag;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	TArray<FInstigator> DisableInstigators;

	TArray<UGravityWhipTargetComponent> TargetComps;

	UPROPERTY(EditAnywhere)
	bool bInvertActivation = false;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	bool bGrabbalbe = true;

	bool bIsEnabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");
		ImpactCallbackComp.OnAnyImpactByPlayer.AddUFunction(this, n"HandleAnyImpactByPlayer");

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");

		GetComponentsByClass(TargetComps);

		if (!bGrabbalbe)
		{
			for (auto TargetComp : TargetComps)
				TargetComp.Disable(Root);			
		}
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		if (bInvertActivation)
			Disable();
		else
			Enable();

		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		if (bInvertActivation)
			Enable();
		else
			Disable();

		
	}

	UFUNCTION()
	private void HandleAnyImpactByPlayer(AHazePlayerCharacter Player)
	{
		if (bIsEnabled)
			Player.KillPlayer(DeathEffect = DeathEffect);
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

//		FPlayerDeathDamageParams Params;

		Player.KillPlayer(DeathEffect = DeathEffect);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
							   TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		AddDisabler(UserComponent);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		RemoveDisabler(UserComponent);
	}	

	UFUNCTION()
	void Enable()
	{
		bIsEnabled = true;
		FauxPhysicsForceComponent.RemoveDisabler(this);	
		Collision.CollisionEnabled = ECollisionEnabled::QueryOnly;
	}

	UFUNCTION()
	void Disable()
	{
		bIsEnabled = false;
		FauxPhysicsForceComponent.AddDisabler(this);
		Collision.CollisionEnabled = ECollisionEnabled::NoCollision;
	}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		if (DisableInstigators.Num() == 0)
			Disable();

		DisableInstigators.AddUnique(DisableInstigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		DisableInstigators.Remove(DisableInstigator);

		if (DisableInstigators.Num() == 0)
			Enable();
	}
}