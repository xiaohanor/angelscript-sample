class ASplitTraversalBouncyBox : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpact");
	}

	UFUNCTION()
	private void OnGroundImpact(AHazePlayerCharacter Player)
	{
		if (Player.IsZoe())
		{
			Player.AddMovementImpulse(FVector(0, 0, 1600));
			SetActorScale3D(FVector(1, 1, 0.2));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ActorScale3D.Z < 1.0)
		{
			SetActorScale3D(FVector(1, 1, Math::FInterpTo(ActorScale3D.Z, 1, DeltaSeconds, 4)));
		}
	}
};