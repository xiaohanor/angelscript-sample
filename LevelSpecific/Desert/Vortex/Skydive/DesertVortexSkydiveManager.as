class ADesertVortexSkydiveManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(15.0);
#endif

	UPROPERTY(EditInstanceOnly)
	AActor FollowActor;

	bool bStarted;

	UFUNCTION()
	void StartSkydive()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			auto MoveComp = UPlayerMovementComponent::Get(Player);
			MoveComp.FollowComponentMovement(FollowActor.RootComponent, this);
		}
		bStarted = true;
	}

	UFUNCTION()
	void StopSkydive()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			auto MoveComp = UPlayerMovementComponent::Get(Player);
			MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bStarted)
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(Player.ActorLocation.Z < FollowActor.ActorLocation.Z + 500)
			{
				StopSkydive();
				return;
			}
		}
	}
}