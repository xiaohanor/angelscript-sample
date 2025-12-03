event void FSkylineMallChaseBillboardMissileSignature();
class ASkylineMallChaseBillboardMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = SplineComp)
	USceneComponent MissileRoot;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MissileTimeLike;
	default MissileTimeLike.UseLinearCurveZeroToOne();
	default MissileTimeLike.Duration = 1.25;

	UPROPERTY(EditInstanceOnly)
	ASkylineMallFloatingRoundBillboard Billboard;

	UPROPERTY()
	FSkylineMallChaseBillboardMissileSignature OnHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MissileTimeLike.BindUpdate(this, n"MissileTimeLikeUpdate");
		MissileTimeLike.BindFinished(this, n"MissileTimeLikeFinished");
	}

	UFUNCTION()
	void Activate()
	{
		MissileRoot.SetHiddenInGame(false, true);
		BP_Activate();
		MissileTimeLike.Play();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION()
	private void MissileTimeLikeUpdate(float CurrentValue)
	{
		FVector Location = SplineComp.GetWorldLocationAtSplineFraction(CurrentValue);
		FRotator Rotation = SplineComp.GetWorldRotationAtSplineFraction(CurrentValue).Rotator();
		MissileRoot.SetWorldLocationAndRotation(Location, Rotation);
	}

	UFUNCTION()
	private void MissileTimeLikeFinished()
	{
		MissileRoot.SetHiddenInGame(true, true);
		BP_MissileExplode();
		Billboard.Collapse();
		OnHit.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_MissileExplode(){}
};