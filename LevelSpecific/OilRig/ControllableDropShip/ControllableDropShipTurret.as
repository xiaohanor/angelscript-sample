UCLASS(Abstract)
class AControllableDropShipTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TurretRoot;

	UPROPERTY(DefaultComponent, Attach = TurretRoot)
	USceneComponent GunnerAttachComp;

	UPROPERTY(DefaultComponent, Attach = TurretRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = "TurretGunBase")
	USpotLightComponent TurretLight;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = "LeftMuzzle")
	UArrowComponent LeftMuzzleComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = "RightMuzzle")
	UArrowComponent RightMuzzleComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = "TurretGunBase")
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = "TurretGunBase")
	USceneComponent ShootTutorialAttachComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	FVector2D AimBSValues = FVector2D::ZeroVector;
	bool bShooting = false;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TurnAroundTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike AlignForCutsceneTimeLike;
	float AlignForCutsceneStartPitch = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TurnAroundTimeLike.BindUpdate(this, n"UpdateTurnAround");
		TurnAroundTimeLike.BindFinished(this, n"FinishTurnAround");

		AlignForCutsceneTimeLike.BindUpdate(this, n"UpdateAlignForCutscene");
	}

	UFUNCTION()
	void TurnAround(bool bSnap)
	{
		if (bSnap)
			SetActorRelativeRotation(FRotator(0.0, 180.0, 0.0));
		else
			TurnAroundTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateTurnAround(float CurValue)
	{
		float Rot = Math::Lerp(0.0, 180.0, CurValue);
		SetActorRelativeRotation(FRotator(0.0, Rot, 0.0));
	}

	UFUNCTION()
	private void FinishTurnAround()
	{

	}

	UFUNCTION()
	void UpdatePitch(float Pitch)
	{
		AimBSValues.Y = Pitch;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentPitch()
	{
		return AimBSValues.Y;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}

	UFUNCTION()
	void AlignForCutscene()
	{
		AlignForCutsceneStartPitch = GetCurrentPitch();
		AlignForCutsceneTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateAlignForCutscene(float CurValue)
	{
		float Pitch = Math::Lerp(AlignForCutsceneStartPitch, 0.0, CurValue);
		UpdatePitch(Pitch);
	}
}