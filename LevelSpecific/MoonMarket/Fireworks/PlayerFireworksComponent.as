class UPlayerFireworksComponent : UActorComponent
{
	AFireworksRocket FireworkRocket;
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	UAnimSequence AimAnim;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BoneFilter;

	void SetFirework(AFireworksRocket NewFirework)
	{
		FireworkRocket = NewFirework;
		FireworkRocket.AttachToActor(Owner, n"RightAttach", EAttachmentRule::SnapToTarget);
		FireworkRocket.SetActorRelativeLocation(FVector(-74.68, -20.45, -15.81));
		FireworkRocket.SetActorRelativeRotation(FRotator(11.1,  8.72, 10.5));
	}

	void LaunchFirework(FVector Direction)
	{
		FireworkRocket.DetachFromActor(EDetachmentRule::KeepWorld);
		FireworkRocket.SetActorRotation(FQuat::MakeFromXZ(Direction, FireworkRocket.ActorUpVector));
		FireworkRocket.LaunchFirework(Direction);
		FireworkRocket = nullptr;
	}

	void CancelFirework()
	{
		if(FireworkRocket != nullptr)
			FireworkRocket.DestroyFirework();

		FireworkRocket = nullptr;
	}
};