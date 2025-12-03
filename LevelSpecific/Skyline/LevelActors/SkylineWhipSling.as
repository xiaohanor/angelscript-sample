class ASkylineWhipSling : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SlingRoot;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent FauxPhysicsConeRotateComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsConeRotateComponent)
	UFauxPhysicsForceComponent FauxPhysicsForceComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsConeRotateComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

//	UPROPERTY(DefaultComponent)
//	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(EditAnywhere)
	float AddedUpImpulse = 500.0;

	UPROPERTY(EditAnywhere)
	float LaunchImpulse = 2500.0;

	AHazePlayerCharacter GrabbingPlayer;

	UPROPERTY(EditAnywhere)
	UAnimSequence Animation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"OnReleased");
		GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnThrown");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (GrabbingPlayer != nullptr)
		{
			FVector ToSling = GrabbingPlayer.ActorLocation - SlingRoot.WorldLocation;
			FauxPhysicsForceComponent.Force = ToSling.GetSafeNormal() * 6000.0;
		}
		else
		{
			FauxPhysicsForceComponent.Force = FVector::ZeroVector;
		}
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		GrabbingPlayer = Cast<AHazePlayerCharacter>(UserComponent.Owner);
		PrintScaled(f"GrabbingActor: {UserComponent.Owner.Name}", 1.0, FLinearColor::Green);

		GrabbingPlayer.StopSlotAnimationByAsset(Animation);
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FVector Impulse)
	{
		auto Player = Cast<AHazePlayerCharacter>(UserComponent.Owner);
		if (Player != nullptr)
		{
			FVector ToSling = SlingRoot.WorldLocation - Player.ActorLocation;
			FVector LaunchDirection = ToSling.GetSafeNormal();
			//float LaunchImpulse = 2000.0;

			Player.AddMovementImpulse(LaunchDirection * (LaunchImpulse + ToSling.Size() * 0.5) + FVector::UpVector * AddedUpImpulse);
		
			Player.PlaySlotAnimation(Animation = Animation, PlayRate =  2.0);
		}

		GrabbingPlayer = nullptr;
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult,
		FVector Impulse)
	{
		auto Player = Cast<AHazePlayerCharacter>(UserComponent.Owner);
		if (Player != nullptr)
		{
			FVector ToSling = SlingRoot.WorldLocation - Player.ActorLocation;
			FVector LaunchDirection = ToSling.GetSafeNormal();
			//float LaunchImpulse = 2000.0;
			Player.AddMovementImpulse(LaunchDirection * LaunchImpulse + FVector::UpVector * AddedUpImpulse);
		
			Player.PlaySlotAnimation(Animation = Animation, PlayRate =  2.0);
		}

		GrabbingPlayer = nullptr;
	}

}