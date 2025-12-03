UCLASS(Abstract)
class USkylineAllyBreakableWindowCleanerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}
}

class ASkylineAllyBreakableWindowCleaner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformSpinPivotComp;

	UPROPERTY(DefaultComponent, Attach = PlatformSpinPivotComp)
	USceneComponent PlatformPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CutableRopePivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeCombatTargetComponent GravityBladeTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityBladeTargetComponent)
	UTargetableOutlineComponent GravityBladeOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent GravityBladeResponseComponent;

	UPROPERTY(DefaultComponent, Attach = PlatformPivotComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY()
	FRuntimeFloatCurve FallSpinCurve;

	UPROPERTY()
	UNiagaraSystem NiagaraSystem;

	UPROPERTY()
	FHazeTimeLike CutTimeLike;

	UPROPERTY()
	FHazeTimeLike SpinTimeLike;
	default SpinTimeLike.UseSmoothCurveZeroToOne();
	default SpinTimeLike.Duration = 3.5;

	UPROPERTY()
	FHazeTimeLike SpinBackTimeLike;
	default SpinBackTimeLike.UseSmoothCurveZeroToOne();
	default SpinBackTimeLike.Duration = 4.5;
	float StartYaw;

	UPROPERTY(EditInstanceOnly)
	APoleClimbActor PoleClimbActorActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CutTimeLike.BindUpdate(this, n"CutTimeLikeUpdate");
		SpinTimeLike.BindUpdate(this, n"SpinTimeLikeUpdate");
		SpinBackTimeLike.BindUpdate(this, n"SpinBackTimeLikeUpdate");
		GravityBladeResponseComponent.OnHit.AddUFunction(this, n"HandleBladeHit");
		PoleClimbActorActor.OnStartPoleClimb.AddUFunction(this, n"HandleStartPoleClimb");
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		CutTimeLike.Play();
		GravityBladeResponseComponent.AddResponseComponentDisable(this);
		CutableRopePivotComp.SetHiddenInGame(true, true);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraSystem, GravityBladeTargetComponent.WorldLocation);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		USkylineAllyBreakableWindowCleanerEventHandler::Trigger_OnHit(this);
		
		BP_Cut();

		Timer::SetTimer(this, n"DelayedSpin", 1.5);
	}

	UFUNCTION()
	private void DelayedSpin()
	{
		SpinTimeLike.Play();
	}

	UFUNCTION()
	private void CutTimeLikeUpdate(float CurrentValue)
	{
		PlatformPivotComp.SetRelativeRotation(FRotator(Math::Lerp(0.0, -90.0, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION()
	private void SpinTimeLikeUpdate(float CurrentValue)
	{
		PlatformSpinPivotComp.SetRelativeRotation(FRotator(0.0, Math::Lerp(0.0, -55.0, CurrentValue), 0.0));
	}

	UFUNCTION()
	private void HandleStartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		PoleClimbActorActor.OnStartPoleClimb.UnbindObject(this);
		StartYaw = PlatformSpinPivotComp.GetRelativeRotation().Yaw;
		SpinTimeLike.Stop();
		SpinBackTimeLike.Play();
	}

	UFUNCTION()
	private void SpinBackTimeLikeUpdate(float CurrentValue)
	{
		PlatformSpinPivotComp.SetRelativeRotation(FRotator(0.0, Math::Lerp(StartYaw, 40.0, CurrentValue), 0.0));
	}

	UFUNCTION(DevFunction)
	void DEVBreak()
	{
		HandleBladeHit(nullptr, FGravityBladeHitData());
	}

	UFUNCTION(BlueprintEvent)
	void BP_Cut(){}
}