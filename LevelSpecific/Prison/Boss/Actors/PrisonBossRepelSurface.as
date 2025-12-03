UCLASS(Abstract)
class APrisonBossRepelSurface : AMagneticFieldRepelSurface
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FoldTimeLike;

	bool bFoldedUp = true;
	float FoldedUpPitch = 10.0;

	float AntennaRotSpeed = 300.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		FoldTimeLike.BindUpdate(this, n"UpdateFold");
		FoldTimeLike.BindFinished(this, n"FinishFold");
	}

	UFUNCTION()
	void FoldUp()
	{
		if (bFoldedUp)
			return;

		bFoldedUp = true;
		FoldTimeLike.Play();

		BP_FoldUp();

		UPrisonBossRepelSurfaceEffectEventHandler::Trigger_FoldUp(this);
	}

	UFUNCTION()
	void FoldDown()
	{
		if (!bFoldedUp)
			return;

		bFoldedUp = false;
		FoldTimeLike.Reverse();

		BP_FoldDown();
	}

	UFUNCTION()
	private void UpdateFold(float CurValue)
	{
		float PlatformPitch = Math::Lerp(90.0, FoldedUpPitch, CurValue);
		SurfaceRoot.SetRelativeRotation(FRotator(PlatformPitch, 0.0, 0.0));
	}

	UFUNCTION(BlueprintEvent)
	void BP_FoldUp() {}

	UFUNCTION(BlueprintEvent)
	void BP_FoldDown() {}

	UFUNCTION()
	private void FinishFold()
	{

	}

	UFUNCTION()
	void SnapFoldUp()
	{
		bFoldedUp = true;
		SurfaceRoot.SetRelativeRotation(FRotator(FoldedUpPitch, 0.0, 0.0));

		BP_FoldUp();
	}

	UFUNCTION()
	void SnapFoldDown()
	{
		bFoldedUp = false;
		SurfaceRoot.SetRelativeRotation(FRotator(90.0, 0.0, 0.0));

		BP_FoldDown();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}
}

class APrisonBossRepelSurfaceManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	TArray<APrisonBossRepelSurface> RepelSurfaces;

	bool bStateLocked = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RepelSurfaces = TListedActors<APrisonBossRepelSurface>().GetArray();
	}

	UFUNCTION()
	void FoldUpSurfaces(bool bSnap)
	{
		if (bStateLocked)
			return;

		for (APrisonBossRepelSurface Surface : RepelSurfaces)
		{
			if (bSnap)
				Surface.SnapFoldUp();
			else
				Surface.FoldUp();
		}
	}

	UFUNCTION()
	void FoldDownSurfaces(bool bSnap)
	{
		if (bStateLocked)
			return;
		
		for (APrisonBossRepelSurface Surface : RepelSurfaces)
		{
			if (bSnap)
				Surface.SnapFoldDown();
			else
				Surface.FoldDown();
		}
	}

	UFUNCTION()
	void LockState()
	{
		bStateLocked = true;
	}

	UFUNCTION()
	void UnlockState()
	{
		bStateLocked = false;
	}
}