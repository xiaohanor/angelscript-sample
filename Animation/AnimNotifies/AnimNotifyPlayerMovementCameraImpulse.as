class UAnimNotifyPlayerMovementCameraImpulse : UAnimNotify
{
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	FHazeCameraImpulse Impulse;
	default Impulse.CameraSpaceImpulse.Z = -500;
	default Impulse.ExpirationForce = 20;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float Scale = 1.0;

	//Should the camera shake only play if the view mode + perspective mode allows it
	UPROPERTY(EditAnywhere, Category = "CameraImpulse", Meta = (EditCondition = "!bPlayInWorld", EditConditionHides))
	bool bRespectPlayerViewMode = true;

#if EDITOR
	default NotifyColor = FColor::Emerald;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "PlayerMovementCamperaImpulse";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MeshComp.Owner);
			if (Player != nullptr)
			{
				if(!bRespectPlayerViewMode || (bRespectPlayerViewMode && Player.IsMovementCameraBehaviorEnabled()))
					Player.ApplyCameraImpulse(Impulse, this);
			}
		return true;
	}
}