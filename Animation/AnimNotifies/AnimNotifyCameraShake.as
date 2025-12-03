class UAnimNotifyCameraShake : UAnimNotify
{
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float Scale = 1.0;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	bool bPlayInWorld = false;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float InnerRadius = 600.0;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float OuterRadius = 600.0;

	//Should the camera shake only play if the view mode + perspective mode allows it
	UPROPERTY(EditAnywhere, Category = "CameraShake", Meta = (EditCondition = "!bPlayInWorld", EditConditionHides))
	bool bRespectPlayerViewMode = false;

#if EDITOR
	default NotifyColor = FColor::Emerald;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "CameraShake";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (bPlayInWorld)
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
				Player.PlayWorldCameraShake(CameraShakeClass, this, MeshComp.Owner.ActorLocation, InnerRadius, OuterRadius, 1.0, Scale);
		}
		else
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
			if (Player != nullptr)
			{
				if(!bRespectPlayerViewMode || (bRespectPlayerViewMode && Player.IsMovementCameraBehaviorEnabled()))
					Player.PlayCameraShake(CameraShakeClass, this, Scale);
			}
		}

		return true;
	}
}