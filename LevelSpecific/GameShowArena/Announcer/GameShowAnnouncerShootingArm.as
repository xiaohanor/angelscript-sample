struct FGameShowAnnouncerArmValues
{
	UPROPERTY()
	FRotator Arm01Rot;
	UPROPERTY()
	FRotator Arm02Rot;
	UPROPERTY()
	FRotator HandRot;
}

class AGameShowAnnouncerShootingArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Arm01;

	UPROPERTY(DefaultComponent, Attach = Arm01)
	UStaticMeshComponent Arm02;

	UPROPERTY(DefaultComponent, Attach = Arm02)
	UStaticMeshComponent Hand;

	UPROPERTY(DefaultComponent, Attach = Hand)
	UStaticMeshComponent Laser;

	UPROPERTY(DefaultComponent, Attach = Hand)
	USceneComponent ShootingLoc;

	UPROPERTY(EditInstanceOnly)
	FGameShowAnnouncerArmValues ShootingRot01;
	UPROPERTY(EditInstanceOnly)
	FGameShowAnnouncerArmValues ShootingRot02;
	UPROPERTY(EditInstanceOnly)
	FGameShowAnnouncerArmValues RecoilRot;

	UPROPERTY(EditInstanceOnly)
	TArray<AGameShowArenaTurretProjectile> Projectiles;

	AGameShowArenaTurretProjectile CurrentProjectile;

	UPROPERTY()
	UCurveFloat ShootingCurve;

	FGameShowAnnouncerArmValues CurrentShootingRot;

	FHazeTimeLike MoveArmTimelike;
	default MoveArmTimelike.Duration = 0.5;

	bool bShootingOn01 = false;
	bool bHasChangedTarget = false;

	bool bShouldTickShootTimer = false;
	float ShootTimer = 0;
	float ShootTimerDuration = 1.25;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveArmTimelike.BindUpdate(this, n"MoveArmTimelikeUpdate");
		MoveArmTimelike.BindFinished(this, n"MoveArmTimelikeFinished");

		CurrentShootingRot = ShootingRot01;
	}

	UFUNCTION()
	void SetHandsHidden(bool bShouldBeHidden)
	{
		SetActorHiddenInGame(bShouldBeHidden);
	}

	UFUNCTION()
	void ActivateShootingHand(bool bOffsetTime)
	{
		if(bOffsetTime)
		{
			ShootTimer = ShootTimerDuration / 2;
		}
		else
		{
			ShootTimer = 0;
		}

		bShouldTickShootTimer = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bShouldTickShootTimer)
			return;

		ShootTimer += DeltaSeconds;
		if(ShootTimer >= ShootTimerDuration)
		{
			ShootTimer = 0;
			Shoot();
		}
	}

	void Shoot()
	{
		MoveArmTimelike.PlayFromStart();
		int Index = bShootingOn01 ? 0 : 1;
		Projectiles[Index].ActivateProjectile(ShootingLoc.WorldLocation);

		FGameShowArenaShootingArmData Data;
		Data.GameShowAnnouncerShootingArm = this;
		UGameShowAnnouncerShootingArmEffectHandler::Trigger_Shoot(this, Data);
	}

	UFUNCTION()
	private void MoveArmTimelikeUpdate(float CurrentValue)
	{
		float Alpha = ShootingCurve.GetFloatValue(CurrentValue);

		if(Alpha >= 0.95 && !bHasChangedTarget)
		{
			bHasChangedTarget = true;
			CurrentShootingRot = bShootingOn01 ? ShootingRot02 : ShootingRot01;
		}

		Arm01.SetRelativeRotation(FQuat::Slerp(CurrentShootingRot.Arm01Rot.Quaternion(), RecoilRot.Arm01Rot.Quaternion(), Alpha));
		Arm02.SetRelativeRotation(FQuat::Slerp(CurrentShootingRot.Arm02Rot.Quaternion(), RecoilRot.Arm02Rot.Quaternion(), Alpha));
		Hand.SetRelativeRotation(FQuat::Slerp(CurrentShootingRot.HandRot.Quaternion(), RecoilRot.HandRot.Quaternion(), Alpha));
	}

	UFUNCTION()
	private void MoveArmTimelikeFinished()
	{
		bHasChangedTarget = false;
		bShootingOn01 = !bShootingOn01;
		int Index = bShootingOn01 ? 0 : 1;
		Projectiles[Index].ActivateDecal();
	}

	UFUNCTION(CallInEditor)
	void SetShootingRot01()
	{
		ShootingRot01.Arm01Rot = Arm01.RelativeRotation;
		ShootingRot01.Arm02Rot = Arm02.RelativeRotation;
		ShootingRot01.HandRot = Hand.RelativeRotation;
	}

	UFUNCTION(CallInEditor)
	void SetShootingRot02()
	{
		ShootingRot02.Arm01Rot = Arm01.RelativeRotation;
		ShootingRot02.Arm02Rot = Arm02.RelativeRotation;
		ShootingRot02.HandRot = Hand.RelativeRotation;
	}

	UFUNCTION(CallInEditor)
	void SetRecoilRot()
	{
		RecoilRot.Arm01Rot = Arm01.RelativeRotation;
		RecoilRot.Arm02Rot = Arm02.RelativeRotation;
		RecoilRot.HandRot = Hand.RelativeRotation;
	}

	UFUNCTION(CallInEditor)
	void PreviewShootingRot01()
	{
		Arm01.SetRelativeRotation(ShootingRot01.Arm01Rot);
		Arm02.SetRelativeRotation(ShootingRot01.Arm02Rot);
		Hand.SetRelativeRotation(ShootingRot01.HandRot);
	}

	UFUNCTION(CallInEditor)
	void PreviewShootingRot02()
	{
		Arm01.SetRelativeRotation(ShootingRot02.Arm01Rot);
		Arm02.SetRelativeRotation(ShootingRot02.Arm02Rot);
		Hand.SetRelativeRotation(ShootingRot02.HandRot);
	}

	UFUNCTION(CallInEditor)
	void PreviewRecoilRot()
	{
		Arm01.SetRelativeRotation(RecoilRot.Arm01Rot);
		Arm02.SetRelativeRotation(RecoilRot.Arm02Rot);
		Hand.SetRelativeRotation(RecoilRot.HandRot);
	}
};