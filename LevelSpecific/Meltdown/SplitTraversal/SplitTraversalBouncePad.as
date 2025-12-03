class ASplitTraversalBouncePad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY()
	float Strength = 2000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpact");
	}

	UFUNCTION()
	private void OnGroundImpact(AHazePlayerCharacter Player)
	{
		Player.AddMovementImpulse(FVector(0, 0, Strength));
		SetActorScale3D(FVector(1, 1, 0.2));
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