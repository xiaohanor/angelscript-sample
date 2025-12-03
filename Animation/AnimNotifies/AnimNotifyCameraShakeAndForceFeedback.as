class UAnimNotifyCameraShakeAndForceFeedback : UAnimNotify
{
	//None means that it tries to get the mesh owner, usually the player. If not found, play on both players. Ignored if using the World option
	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer TargetPlayer = EHazeSelectPlayer::None;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(EditAnywhere)
	float CameraShakeScale = 1.0;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY(EditAnywhere)
	float ForceFeedbackScale = 1.0;

	UPROPERTY(EditAnywhere)
	bool bPlayInWorld = false;

	UPROPERTY(EditAnywhere)
	FName WorldSpaceSocket;

	UPROPERTY(EditAnywhere)
	float InnerRadius = 600.0;

	UPROPERTY(EditAnywhere)
	float OuterRadius = 1200.0;

#if EDITOR
	default NotifyColor = FColor::Turquoise;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "CameraShakeForceFeedback";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;

		if (bPlayInWorld)
		{
			FVector Origin = MeshComp.Owner.ActorLocation;
			if (WorldSpaceSocket != NAME_None && MeshComp.DoesSocketExist(WorldSpaceSocket))
				Origin = MeshComp.GetSocketLocation(WorldSpaceSocket);

			for (AHazePlayerCharacter Player : Game::GetPlayers())
				Player.PlayWorldCameraShake(CameraShakeClass, this, Origin, InnerRadius, OuterRadius, 1.0, CameraShakeScale);

			ForceFeedback::PlayWorldForceFeedback(ForceFeedbackEffect, Origin, true, n"AnimNotify", InnerRadius, OuterRadius - InnerRadius);
		}
		else
		{
			if (TargetPlayer == EHazeSelectPlayer::Both)
			{
				for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
				{
					CurPlayer.PlayCameraShake(CameraShakeClass, this, CameraShakeScale);
					CurPlayer.PlayForceFeedback(ForceFeedbackEffect, false, true, this, 1.0);
				}
			}
			else
			{
				AHazePlayerCharacter Player = nullptr;
				if (TargetPlayer == EHazeSelectPlayer::None)
					Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
				else if (TargetPlayer == EHazeSelectPlayer::Mio)
					Player = Game::Mio;
				else if (TargetPlayer == EHazeSelectPlayer::Zoe)
					Player = Game::Zoe;

				if (Player != nullptr)
				{
					Player.PlayCameraShake(CameraShakeClass, this, CameraShakeScale);
					Player.PlayForceFeedback(ForceFeedbackEffect, false, true, this, 1.0);
				}
				else
				{
					for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
					{
						CurPlayer.PlayCameraShake(CameraShakeClass, this, CameraShakeScale);
						CurPlayer.PlayForceFeedback(ForceFeedbackEffect, false, true, this, 1.0);
					}
				}
			}
		}

		return true;
	}
}