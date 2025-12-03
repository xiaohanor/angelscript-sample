class UGameShowArenaBombDisposalInteractionComponent : UInteractionComponent
{
	UPROPERTY(EditAnywhere)
	float MaxInteractionRadius = 500;

	UPROPERTY(EditAnywhere)
	float MinInteractionRadius = 100;

	UPROPERTY(EditAnywhere)
	float AllowedPlayerProximity = 50;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		if (!IsComponentTickEnabled())
			return;

		AHazePlayerCharacter TargetPlayer;
		switch (UsableByPlayers)
		{
			case EHazeSelectPlayer::Mio:
				TargetPlayer = Game::Mio;
				break;
			case EHazeSelectPlayer::Zoe:
				TargetPlayer = Game::Zoe;
				break;
			case EHazeSelectPlayer::Both:
				if (Game::Zoe.GetSquaredDistanceTo(Owner) < Game::Mio.GetSquaredDistanceTo(Owner))
					TargetPlayer = Game::Zoe;
				else
					TargetPlayer = Game::Mio;
				break;
			case EHazeSelectPlayer::None:
			case EHazeSelectPlayer::Specified:
				return;
		}

		FVector CircleToPlayer = (TargetPlayer.ActorLocation - Owner.ActorLocation).VectorPlaneProject(Owner.ActorUpVector);
		float Radius = Math::Max(Math::Min(MaxInteractionRadius, CircleToPlayer.Size()), MinInteractionRadius);
		FVector PlayerPointInCircle = CircleToPlayer.GetSafeNormal() * Radius;

		FVector CircleToOtherPlayer = (TargetPlayer.OtherPlayer.ActorLocation - Owner.ActorLocation).VectorPlaneProject(Owner.ActorUpVector);
		if (CircleToOtherPlayer.Size() <= MaxInteractionRadius * 1.5)
		{
			float OtherRadius = Math::Max(Math::Min(MaxInteractionRadius, CircleToOtherPlayer.Size()), MinInteractionRadius);
			FVector OtherPlayerPointInCircle = CircleToOtherPlayer.GetSafeNormal() * OtherRadius;

			float Dist = PlayerPointInCircle.Distance(OtherPlayerPointInCircle);
			if (Dist < AllowedPlayerProximity)
				return;
		}

		RelativeLocation = Owner.ActorTransform.InverseTransformVector(PlayerPointInCircle);
		RelativeRotation = FRotator::MakeFromXZ(-RelativeLocation, Owner.ActorUpVector);
	}
};