event void FReleaseHackableDroneForVO();

UCLASS(Abstract)
class AMagneticFieldDockingStation : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent StationRoot;

	UPROPERTY(DefaultComponent, Attach = StationRoot)
	USceneComponent TetheredActorRoot;

	UPROPERTY(DefaultComponent, Attach = StationRoot)
	UFauxPhysicsAxisRotateComponent LeftClampRoot;
	default LeftClampRoot.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = StationRoot)
	UFauxPhysicsAxisRotateComponent RightClampRoot;
	default RightClampRoot.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(EditInstanceOnly)
	ARemoteHackableTetheredActor TetheredActor;

	UPROPERTY()
	FReleaseHackableDroneForVO BothClampsOpened();

	bool bLeftClampOpened = false;
	bool bRightClampOpened = false;
	bool bBothClampsOpened = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timer::SetTimer(this, n"SetTetheredActorLocation", 0.2);

		SetActorControlSide(Game::Zoe);

		LeftClampRoot.OnMinConstraintHit.AddUFunction(this, n"LeftConstraintHit");
		RightClampRoot.OnMaxConstraintHit.AddUFunction(this, n"RightConstraintHit");

		LeftClampRoot.OnMaxConstraintHit.AddUFunction(this, n"LeftConstraintReset");
		RightClampRoot.OnMinConstraintHit.AddUFunction(this, n"RightConstraintReset");
	}

	UFUNCTION(NotBlueprintCallable)
	void SetTetheredActorLocation()
	{
		TetheredActor.TranslateComp.SetWorldLocation(TetheredActorRoot.WorldLocation);
	}

	UFUNCTION()
	private void LeftConstraintHit(float Strength)
	{
		bLeftClampOpened = true;

		CheckClampOpened();
	}

	UFUNCTION()
	private void RightConstraintHit(float Strength)
	{
		bRightClampOpened = true;

		CheckClampOpened();
	}

	UFUNCTION()
	private void LeftConstraintReset(float Strength)
	{
		bLeftClampOpened = false;
	}

	UFUNCTION()
	private void RightConstraintReset(float Strength)
	{
		bRightClampOpened = false;
	}

	void CheckClampOpened()
	{
		if (!Game::Zoe.HasControl())
			return;

		if (bBothClampsOpened)
			return;
		
		if (bRightClampOpened && bLeftClampOpened)
		{
			CrumbBothClampsOpened();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbBothClampsOpened()
	{
		bBothClampsOpened = true;
		TetheredActor.Enable();
		BothClampsOpened.Broadcast();
	}
}