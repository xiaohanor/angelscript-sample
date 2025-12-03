class ADesertGrappleAntiBonkActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> GrappleIgnoreActors;

	TPerPlayer<bool> IgnoringActors;

	UFUNCTION()
	void StartIgnoringActors(AHazePlayerCharacter Player)
	{
		if (!IgnoringActors[Player])
		{
			IgnoringActors[Player] = true;
			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
			MoveComp.AddMovementIgnoresActors(this, GrappleIgnoreActors);
		}
	}

	UFUNCTION()
	void StopIgnoringActors(AHazePlayerCharacter Player)
	{
		if (IgnoringActors[Player])
		{
			IgnoringActors[Player] = false;
			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
			MoveComp.RemoveMovementIgnoresActor(this);
		}
	}
}