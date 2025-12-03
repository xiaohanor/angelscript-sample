event void FOnCraftTempleAcidStatueActivated();
event void FOnCraftTempleAcidStatueDeactivated();
event void FOnCraftTempleAcidStatueAlmostFinished();

class AAcidStatue : AHazeActor
{
	UPROPERTY()
	FOnCraftTempleAcidStatueActivated OnCraftTempleAcidStatueActivated;

	UPROPERTY()
	FOnCraftTempleAcidStatueDeactivated OnCraftTempleAcidStatueDeactivated;

	UPROPERTY()
	FOnCraftTempleAcidStatueAlmostFinished OnCraftTempleAcidStatueAlmostFinished;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StatueRoot;

	UPROPERTY(DefaultComponent, Attach = StatueRoot)
	UStaticMeshComponent GlowUpFront;

	UPROPERTY(DefaultComponent, Attach = StatueRoot)
	UStaticMeshComponent AcidBall;

	UPROPERTY(DefaultComponent, Attach = AcidBall)
	UAcidResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = AcidBall)
	UTeenDragonAcidAutoAimComponent AutoAim;
	default AutoAim.AutoAimMaxAngle = 10.0;

	UPROPERTY(DefaultComponent, Attach = StatueRoot)
	USceneComponent JawRoot;

	UPROPERTY(DefaultComponent, Attach = JawRoot)
	UStaticMeshComponent JawMesh;

	UPROPERTY(DefaultComponent, Attach = StatueRoot)
	USceneComponent MouthRoofRoot;

	UPROPERTY(DefaultComponent, Attach = MouthRoofRoot)
	UStaticMeshComponent LeftEye;

	UPROPERTY(DefaultComponent, Attach = MouthRoofRoot)
	UStaticMeshComponent RightEye;

	UPROPERTY(DefaultComponent, Attach = MouthRoofRoot)
	UStaticMeshComponent MouthRoofMesh;

	UPROPERTY(DefaultComponent, Attach = StatueRoot)
	UStaticMeshComponent StatueBase;

	UPROPERTY(DefaultComponent, Attach = StatueRoot)
	UNiagaraComponent AcidEffect;
	default AcidEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"AcidStatueCountdownCapability");
	
	UPROPERTY(EditAnywhere)
	float Duration = 6.0;

	UPROPERTY(EditAnywhere)
	float AlmostFinishedDuration = 3.0;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EmissiveMat;
	UMaterialInterface GlowingPartsOriginalMat;
	UMaterialInterface BallBaseOriginalMat;

	float AcidHitAmount;
	float AcidGainAmount = 0.1;
	float UpMouthPitchAmount = 17.0;
	float DownMouthPitchAmount = -26.0;
	FRotator MouthRoofOpenRot;
	FRotator MouthRoofStartRot;
	FRotator JawOpenRot;
	FRotator JawStartRot;
	FHazeAcceleratedRotator AccelMouthRoofRotator;
	FHazeAcceleratedRotator AccelJawRotator;

	bool bStatueActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MouthRoofStartRot = MouthRoofRoot.RelativeRotation; 
		JawStartRot = JawRoot.RelativeRotation; 

		MouthRoofOpenRot = MouthRoofRoot.RelativeRotation + FRotator(UpMouthPitchAmount, 0, 0);
		JawOpenRot = JawRoot.RelativeRotation + FRotator(DownMouthPitchAmount, 0, 0);

		MouthRoofRoot.RelativeRotation = MouthRoofOpenRot;
		JawRoot.RelativeRotation = JawOpenRot;

		GlowingPartsOriginalMat = LeftEye.GetMaterial(0);
		BallBaseOriginalMat = AcidBall.GetMaterial(0);

		ResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FRotator TargetMouthRoofRotation;
		FRotator TargetJawRotation;

		if (bStatueActive)
		{
			TargetMouthRoofRotation = MouthRoofStartRot;
			TargetJawRotation = JawStartRot;
		}	
		else
		{
			TargetMouthRoofRotation = MouthRoofOpenRot;
			TargetJawRotation = JawOpenRot;
		}

		AccelMouthRoofRotator.AccelerateTo(TargetMouthRoofRotation, 0.5, DeltaSeconds);
		AccelJawRotator.AccelerateTo(TargetJawRotation, 0.5, DeltaSeconds);
		MouthRoofRoot.RelativeRotation = AccelMouthRoofRotator.Value;
		JawRoot.RelativeRotation = AccelJawRotator.Value;		
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (bStatueActive)
			return;

		AcidHitAmount += AcidGainAmount;

		if (AcidHitAmount >= 1.0)
		{
			bStatueActive = true;
		}
	}

	void ActivateStatue()
	{
		AcidEffect.Activate();
		UAcidStatueEffectHandler::Trigger_OnMetalActivated(this);
		AcidBall.SetMaterial(0, EmissiveMat);
		LeftEye.SetMaterial(0, EmissiveMat);
		RightEye.SetMaterial(0, EmissiveMat);
		GlowUpFront.SetMaterial(0, EmissiveMat);
		OnCraftTempleAcidStatueActivated.Broadcast();
	}

	void DeactivateStatue()
	{
		bStatueActive = false;
		AcidEffect.Activate();
		UAcidStatueEffectHandler::Trigger_OnMetalDeactivated(this);
		AcidBall.SetMaterial(0, BallBaseOriginalMat);
		LeftEye.SetMaterial(0, GlowingPartsOriginalMat);
		RightEye.SetMaterial(0, GlowingPartsOriginalMat);
		GlowUpFront.SetMaterial(0, GlowingPartsOriginalMat);
		AcidHitAmount = 0;
		OnCraftTempleAcidStatueDeactivated.Broadcast();
	}
};