event void FMaxSecurityLaserCutterGuardDestroyedEvent();
event void FMaxSecurityLaserCutterGuardActivateBeam();

UCLASS(Abstract)
class AMaxSecurityLaserCutterGuard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GuardRoot;

	UPROPERTY(DefaultComponent, Attach = GuardRoot)
	UCapsuleComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = GuardRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = "LeftHand")
	UNiagaraComponent LeftBeamComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = "RightHand")
	UNiagaraComponent RightBeamComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterGuardPlatform Platform;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DropTimeLike;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutter LaserCutter;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence FallAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LandAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ToShootAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ShootAnim;

	UPROPERTY()
	FMaxSecurityLaserCutterGuardDestroyedEvent OnGuardDestroyed;

	UPROPERTY()
	FMaxSecurityLaserCutterGuardActivateBeam OnActivateBeam;

	FVector StartLocation;
	FVector DropStartLocation;

	bool bDropped = false;

	FName DefaultCollisionProfile;

	bool bStunActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DropTimeLike.BindUpdate(this, n"UpdateDrop");
		DropTimeLike.BindFinished(this, n"FinishDrop");

		LeftBeamComp.SetFloatParameter(n"BeamWidth", 250.0);
		RightBeamComp.SetFloatParameter(n"BeamWidth", 250.0);

		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"MagnetBurst");

		StartLocation = GetActorRelativeLocation();

		DefaultCollisionProfile = CollisionComp.CollisionProfileName;
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		if (!bDropped)
			return;

		if (bStunActive)
			LaserCutter.RemoveStunner();
		
		bStunActive = false;
		bDropped = false;
		LeftBeamComp.Deactivate();
		RightBeamComp.Deactivate();

		OnGuardDestroyed.Broadcast();

		Platform.HidePlatform();

		FMaxSecurityLaserCutterGuardKillParams KillParams;
		KillParams.KillDirection = (ActorLocation - Game::Zoe.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		UMaxSecurityLaserCutterGuardEffectEventHandler::Trigger_Kill(this, KillParams);

		Reset();
	}

	UFUNCTION()
	void DropDown()
	{
		Timer::SetTimer(this, n"ActuallyDrop", Math::RandRange(0.1, 1.0));
	}

	UFUNCTION()
	void ActuallyDrop()
	{
		SetActorHiddenInGame(false);

		DropStartLocation = ActorLocation;

		DropTimeLike.PlayFromStart();

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = FallAnim;
		AnimParams.bLoop = true;
		AnimParams.BlendTime = 0.0;

		SkelMeshComp.PlaySlotAnimation(AnimParams);

		Platform.RevealPlatform();

		UMaxSecurityLaserCutterGuardEffectEventHandler::Trigger_Spawn(this);
	}

	UFUNCTION()
	private void UpdateDrop(float CurValue)
	{
		FVector Loc = Math::Lerp(DropStartLocation, DropStartLocation - (FVector::UpVector * 2000.0), CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION()
	private void FinishDrop()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = LandAnim;

		FHazeAnimationDelegate BlendedOut;
		BlendedOut.BindUFunction(this, n"LandAnimFinished");

		FHazeAnimationDelegate BlendedIn;
		SkelMeshComp.PlaySlotAnimation(BlendedIn, BlendedOut, AnimParams);

		bDropped = true;

		UMaxSecurityLaserCutterGuardEffectEventHandler::Trigger_Land(this);
	}

	UFUNCTION()
	private void LandAnimFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = ToShootAnim;

		FHazeAnimationDelegate BlendedOut;
		BlendedOut.BindUFunction(this, n"ToShootAnimFinished");

		FHazeAnimationDelegate BlendedIn;
		SkelMeshComp.PlaySlotAnimation(BlendedIn, BlendedOut, AnimParams);

		Timer::SetTimer(this, n"ActivateBeam", 1.1);
	}

	UFUNCTION()
	private void ToShootAnimFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = ShootAnim;
		AnimParams.bLoop = true;

		SkelMeshComp.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void ActivateBeam()
	{
		if (!bDropped)
			return;

		FVector LeftBeamTargetLoc = LeftBeamComp.WorldTransform.InverseTransformPosition(LaserCutter.LaserRoot.WorldLocation);
		LeftBeamComp.SetVectorParameter(n"BeamEnd", LeftBeamTargetLoc);
		LeftBeamComp.Activate(true);

		FVector RightBeamTargetLoc = RightBeamComp.WorldTransform.InverseTransformPosition(LaserCutter.LaserRoot.WorldLocation);
		RightBeamComp.SetVectorParameter(n"BeamEnd", RightBeamTargetLoc);
		RightBeamComp.Activate(true);

		bStunActive = true;
		LaserCutter.AddStunner();

		OnActivateBeam.Broadcast();

		UMaxSecurityLaserCutterGuardEffectEventHandler::Trigger_ActivateBeam(this);
	}

	void Reset()
	{
		SetActorRelativeLocation(StartLocation);
	}
}

class UMaxSecurityLaserCutterGuardEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AMaxSecurityLaserCutterGuard Guard;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Guard = Cast<AMaxSecurityLaserCutterGuard>(Owner);
	}

	UFUNCTION(BlueprintEvent)
	void Spawn() {}
	UFUNCTION(BlueprintEvent)
	void Land() {}
	UFUNCTION(BlueprintEvent)
	void ActivateBeam() {}
	UFUNCTION(BlueprintEvent)
	void Kill(FMaxSecurityLaserCutterGuardKillParams Params) {}
}

struct FMaxSecurityLaserCutterGuardKillParams
{
	UPROPERTY()
	FVector KillDirection;
}