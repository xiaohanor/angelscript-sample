UCLASS(Abstract)
class UIslandNunchuckEffectHandler : UHazeEffectEventHandler
{

    // The owner started a standard melee attack (Nunchuck.AttackStarted)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void AttackStarted(FIslandNunchuckAttackData Data) {}

	// The owner finished a melee attack (Nunchuck.AttackCompleted)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void AttackCompleted(FIslandNunchuckAttackData Data) {}

	// The owner hit with a melee attack (Nunchuck.AttackImpact)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void AttackImpact(FIslandNunchuckEffectHandlerAttackImpactData Data) {}

	// The nunchucks became visible (Nunchuck.NunchuckActivated)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void NunchuckActivated() {}

	// The nunchucks became invisible (Nunchuck.NunchuckDeactivated)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void NunchuckDeactivated() {}
}

struct FIslandNunchuckEffectHandlerAttackImpactData
{
	UPROPERTY(BlueprintReadOnly)
	AActor Target;

	FIslandNunchuckEffectHandlerAttackImpactData(AActor InTarget)
	{
		Target = InTarget;
	}
}


struct FIslandNunchuckAttackData
{
	UPROPERTY(BlueprintReadOnly)
	FName AttackName = NAME_None;

	UPROPERTY(BlueprintReadOnly)
	int ComboIndex = -1;

	UPROPERTY(BlueprintReadOnly)
	bool bIsFinalAttackInComboChain = false;
}


UCLASS(Abstract)
class APlayerIslandNunchuckTriggerAtLocationEffect : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent Mesh;
	default Mesh.RelativeRotation = FRotator(0.0, 180.0, 0.0);

	float LifeTime = 1.0;
	bool bInvertEffect = false;
	FRuntimeFloatCurve TrailCurve;
	FRuntimeFloatCurve VisibilityCurve;

	private float CurrentActiveTime = 0.0;
	private UMaterialInstanceDynamic SlashMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SlashMaterial = Mesh.CreateDynamicMaterialInstance(0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentActiveTime += DeltaSeconds;
		float Alpha = Math::Min(CurrentActiveTime / LifeTime, 1.0);
		float VisbilityAlpha = Math::Min(CurrentActiveTime / LifeTime, 1.0);

		if(TrailCurve.NumKeys > 0)
			Alpha = TrailCurve.GetFloatValue(Alpha);

		if(VisibilityCurve.NumKeys > 0)
			VisbilityAlpha = VisibilityCurve.GetFloatValue(Alpha);

		float Value = 0;
		if(bInvertEffect)
			Value = Math::Lerp(1.0, -1.0, Alpha);
		else
			Value = Math::Lerp(-1.0, 1.0, Alpha);

		SlashMaterial.SetScalarParameterValue(n"Y Offset", Value);
		SlashMaterial.SetScalarParameterValue(n"Noise Mask Power", VisbilityAlpha);
		if(CurrentActiveTime >= LifeTime)
		{
			DestroyActor();
		}
	}
}