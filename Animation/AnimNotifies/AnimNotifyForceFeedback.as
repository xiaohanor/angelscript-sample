class UAnimNotifyForceFeedback : UAnimNotify
{
	//None means that it tries to get the mesh owner, usually the player. If not found, play on both players. Ignored if using the World option
	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer TargetPlayer = EHazeSelectPlayer::None;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY(EditAnywhere)
	float Scale = 1.0;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	bool bPlayInWorld = false;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float InnerRadius = 600.0;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float OuterRadius = 600.0;

#if EDITOR
	default NotifyColor = FColor::Orange;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "ForceFeedback";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;

		if (bPlayInWorld)
			ForceFeedback::PlayWorldForceFeedback(ForceFeedbackEffect, MeshComp.Owner.ActorLocation, true, n"AnimNotify", InnerRadius, OuterRadius);
		else
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
			if (Player != nullptr && TargetPlayer == EHazeSelectPlayer::None)
				Player.PlayForceFeedback(ForceFeedbackEffect, false, true, this, Scale);
			else if ((TargetPlayer == EHazeSelectPlayer::Mio) && (Game::Mio != nullptr))
				Game::Mio.PlayForceFeedback(ForceFeedbackEffect, false, true, this, Scale);
			else if ((TargetPlayer == EHazeSelectPlayer::Zoe) && (Game::Zoe != nullptr))
				Game::Zoe.PlayForceFeedback(ForceFeedbackEffect, false, true, this, Scale);
			else if (TargetPlayer == EHazeSelectPlayer::Both)
			{
				for (AHazePlayerCharacter _Player : Game::GetPlayers())
				{
					_Player.PlayForceFeedback(ForceFeedbackEffect, false, true, this, Scale);
				}
			}
			else if (TargetPlayer == EHazeSelectPlayer::None)
			{
				for (AHazePlayerCharacter _Player : Game::GetPlayers())
				{
					_Player.PlayForceFeedback(ForceFeedbackEffect, false, true, this, Scale);
				}
			}
		}

		return true;
	}
}