struct FWyrmShockwaveParams
{
	UPROPERTY()
	FVector Location;
}

struct FWyrmAttackTargetParams
{
	FWyrmAttackTargetParams(AHazeActor AttackTarget) { Target = AttackTarget; };

	UPROPERTY()
	AHazeActor Target;	
}

struct FWyrmCrystalSegmentDamageParams
{
	FWyrmCrystalSegmentDamageParams(USummitWyrmTailSegmentComponent Segment) { HitSegment = Segment; };

	UPROPERTY()
	USummitWyrmTailSegmentComponent HitSegment;	
}

UCLASS(Abstract)
class USummitWyrmEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateShockWave(FWyrmShockwaveParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttack(FWyrmAttackTargetParams TargetParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEndAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEndTelegraphAttack() {}

	UFUNCTION()
	void UpdateTelegraphFX(UNiagaraComponent NiagaraComp) 
	{
		if (NiagaraComp == nullptr)
			return;

		NiagaraComp.SetVectorParameter(n"Start", Owner.ActorTransform.TransformPosition(FVector(0.0, -1000, -1600)));
		NiagaraComp.SetVectorParameter(n"End", Owner.ActorTransform.TransformPosition(  FVector(0.0,  1000, 1600)));

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrystalSegmentSmashed(FWyrmCrystalSegmentDamageParams HitSegmentParams) {}


}