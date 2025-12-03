class AKiteFlightWindTunnelSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default Billboard.SpriteName = "T_Loft_Spline";
#endif

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = SplineComp)
	UNiagaraComponent EffectComp;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		float VFXSpawnRate = SplineComp.SplineLength/100.0;
		EffectComp.SetNiagaraVariableFloat("SpawnRate", VFXSpawnRate);
	}
}