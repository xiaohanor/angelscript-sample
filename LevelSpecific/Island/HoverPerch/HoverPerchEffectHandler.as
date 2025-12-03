struct FHoverPerchDestroyedEffectParams
{
	UPROPERTY()
	FVector PerchLocationAtDestruction;
}

struct FHoverPerchOnPlayerRespawnedEffectParams
{
	UPROPERTY()
	FVector PerchLocationAtRespawn;
}

struct FHoverPerchOnStartGrindingEffectParams
{
	UPROPERTY()
	USceneComponent GrindAttachComponent;
}

struct FHoverPerchOnLockedToPerchEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter PlayerLocker;
}

struct FHoverPerchOnImpactedOtherPerchEffectParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactVelocity;

	UPROPERTY()
	float SpeedTowardsImpact;
}

struct FHoverPerchOnImpactedWorldEffectParams
{
	UPROPERTY()
	float SpeedTowardsImpact;

	UPROPERTY()
	UPhysicalMaterial ImpactedMaterial;
}

struct FHoverPerchOnDashedParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FHoverPerchOnJumpedFromPerchParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FHoverPerchEnterGrindEffectParams
{
	UPROPERTY()
	FVector PerchLocation;
	
	UPROPERTY()
	AHoverPerchGrindSpline GrindSpline;
}

struct FHoverPerchSwitchDirectionParams
{
	UPROPERTY()
	FVector PerchLocation;

	UPROPERTY()
	AHoverPerchActor OtherPerchActor;
}

UCLASS(Abstract)
class UHoverPerchEffectHandler : UHazeEffectEventHandler
{
	FLinearColor LastColor;
	FLinearColor CurrentColor;
	FLinearColor TargetColor;

	AHoverPerchActor PerchActor;

	float TimeLastColorChanged = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchActor = Cast<AHoverPerchActor>(Owner);
		devCheck(PerchActor != nullptr, f"{this} was put on something which is not a hover perch actor");

		CurrentColor = PerchActor.DefaultColor;
		LastColor = PerchActor.DefaultColor;
		TargetColor = PerchActor.DefaultColor;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateColor();
	}

	private void UpdateColor()
	{
		float AlphaToNewColor = Math::GetPercentageBetweenClamped(TimeLastColorChanged, TimeLastColorChanged + PerchActor.ColorChangeDuration, Time::GameTimeSeconds);
		CurrentColor = FLinearColor::LerpUsingHSV(LastColor, TargetColor, AlphaToNewColor);
		PerchActor.ThrusterEffect.SetColorParameter(n"LinearColor", CurrentColor);
		PerchActor.TrailEffectComp.SetColorParameter(n"LinearColor", CurrentColor);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLockedToPlayer(FHoverPerchOnLockedToPerchEffectParams Params)
	{
		LastColor = CurrentColor;
		if(Params.PlayerLocker.IsMio())
			TargetColor = PerchActor.MioColor;
		else
			TargetColor = PerchActor.ZoeColor;

		TimeLastColorChanged = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnlockedFromPlayer()
	{
		TimeLastColorChanged = Time::GameTimeSeconds;

		TargetColor = PerchActor.DefaultColor;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPerchDestroyed(FHoverPerchDestroyedEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerRespawnedWithPerch(FHoverPerchOnPlayerRespawnedEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGrinding(FHoverPerchOnStartGrindingEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedGrinding() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactedOtherPerch(FHoverPerchOnImpactedOtherPerchEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDashed(FHoverPerchOnDashedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandedOnPerch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJumpedFromPerch(FHoverPerchOnJumpedFromPerchParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCollided(FHoverPerchOnImpactedWorldEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterConnectionGrindSpline(FHoverPerchEnterGrindEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwitchDirection(FHoverPerchSwitchDirectionParams Params) {}
}