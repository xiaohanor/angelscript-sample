UCLASS(Abstract)
class APrisonBossBrainPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMeshComp;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent BrokenMeshComp;
	default BrokenMeshComp.bHiddenInGame = true;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RetractTimeLike;
	default RetractTimeLike.bCurveUseNormalizedTime = true;

	UPROPERTY(EditAnywhere)
	bool bRetracted = false;

	float MaxOffset = 3000.0;
	float RetractOffset = 3000.0;

	bool bBroken = false;

	UPROPERTY(BlueprintReadOnly)
	float CurrentAlpha = 0.0;

	bool bRetracting = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bRetracted)
		{
			PlatformRoot.SetRelativeLocation(FVector(MaxOffset, 0.0, 0.0));
		}
		else
		{
			PlatformRoot.SetRelativeLocation(FVector::ZeroVector);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RetractTimeLike.BindUpdate(this, n"UpdateRetract");
		RetractTimeLike.BindFinished(this, n"FinishRetract");
	}

	UFUNCTION()
	void SnapRetract()
	{
		PlatformRoot.SetRelativeLocation(FVector(MaxOffset, 0.0, 0.0));
	}

	UFUNCTION()
	void SnapReveal()
	{
		PlatformRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION()
	void Retract(float Duration = 12.0, float Offset = 3000.0)
	{
		bRetracting = true;
		RetractOffset = Offset;
		RetractTimeLike.SetPlayRate(1.0/Duration);
		RetractTimeLike.PlayFromStart();

		UPrisonBossBrainPlatformEffectEventHandler::Trigger_StartRetract(this);
	}

	UFUNCTION()
	void Reveal(float Duration = 3.0)
	{
		bRetracting = false;
		RetractTimeLike.SetPlayRate(1.0/Duration);
		RetractTimeLike.ReverseFromEnd();

		UPrisonBossBrainPlatformEffectEventHandler::Trigger_StartReveal(this);
	}

	UFUNCTION()
	private void UpdateRetract(float CurValue)
	{
		float Offset = Math::Lerp(0.0, RetractOffset, CurValue);
		PlatformRoot.SetRelativeLocation(FVector(Offset, 0.0, 0.0));

		CurrentAlpha = CurValue;
	}

	UFUNCTION()
	private void FinishRetract()
	{
		if (bRetracting)
			UPrisonBossBrainPlatformEffectEventHandler::Trigger_FinishRetract(this);
		else
			UPrisonBossBrainPlatformEffectEventHandler::Trigger_FinishReveal(this);
	}

	UFUNCTION()
	void BreakPlatform()
	{
		if (bBroken)
			return;

		bBroken = true;

		BrokenMeshComp.SetHiddenInGame(false);
		PlatformMeshComp.SetHiddenInGame(true);
		PlatformMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		BP_BreakPlatform();

		UPrisonBossBrainPlatformEffectEventHandler::Trigger_BreakPlatform(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_BreakPlatform() {}
}