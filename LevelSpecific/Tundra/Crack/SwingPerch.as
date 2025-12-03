class ASwingPerch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent FauxComp;

	UPROPERTY(DefaultComponent, Attach = FauxComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditInstanceOnly)
	APerchPointActor PerchPoint;

	UPROPERTY(EditInstanceOnly)
	float ForceWhenLanding = 1100.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPoint.OnPlayerStartedPerchingEvent.AddUFunction(this, n"PlayerLandedOnPerch");
		PerchPoint.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"PlayerJumpedOffPerch");
	}

	UFUNCTION()
	void PlayerLandedOnPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchComp)
	{
		UPlayerMovementComponent PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		FVector PreviousVelocity = PlayerMoveComp.PreviousVelocity;
		FVector PreviousHorizontalVelocity = PreviousVelocity.ConstrainToPlane(PlayerMoveComp.WorldUp);
		
		PrintToScreen(""+PreviousHorizontalVelocity.Size(), 3.f);

		if(PreviousHorizontalVelocity.Size() >= 400)
		{
			float ImpulseScalar = Math::GetMappedRangeValueClamped(FVector2D(400, 1000), FVector2D(0.4, 1), PreviousHorizontalVelocity.Size());
			FauxComp.ApplyForce(Player.ActorLocation, PreviousHorizontalVelocity.GetSafeNormal() * (ForceWhenLanding * ImpulseScalar));
		}


	}

	UFUNCTION()
	void PlayerJumpedOffPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchComp)
	{
		UPlayerMovementComponent PlayerMoveComp = UPlayerMovementComponent::Get(Player);

		if(Math::Abs(PlayerMoveComp.MovementInput.DotProduct(PerchComp.ForwardVector)) >= 0.3)
		{
			FauxComp.ApplyForce(Player.ActorLocation, -Player.ActorForwardVector * ForceWhenLanding);
		}
	}
};