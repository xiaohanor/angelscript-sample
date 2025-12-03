event void FOnBattlefieldRespondToPlayerWithinRange(AHazePlayerCharacter Player);

class UBattlefieldRespondToPlayerComponent : UActorComponent
{
	UPROPERTY()
	FOnBattlefieldRespondToPlayerWithinRange OnBattlefieldRespondToPlayerWithinRange;

	UPROPERTY(EditAnywhere)
	float ResponseDistance = 500.0;

	bool bResponseFired;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			float ConstrainedDist = (Player.ActorLocation - Owner.ActorLocation).ConstrainToPlane(FVector::UpVector).Size();

			if (ConstrainedDist < ResponseDistance)
			{
				SetComponentTickEnabled(false);
				OnBattlefieldRespondToPlayerWithinRange.Broadcast(Player);
			}
		}	
	}

	UFUNCTION()
	void ResetReponse()
	{
		SetComponentTickEnabled(true);
	}
}

