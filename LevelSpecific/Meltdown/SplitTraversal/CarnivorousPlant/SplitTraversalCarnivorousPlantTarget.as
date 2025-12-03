event void FCarnivorousPlantTargetSignature();

UCLASS(Abstract)
class USplitTraversalCarnivorousPlantTargetEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBitten() {}
}

class ASplitTraversalCarnivorousPlantTarget : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent AlongCableVFXComp;

	UPROPERTY(EditInstanceOnly)
	AActor CableActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	float TargetRadius = 250.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike AlongCableTimeLike;
	default AlongCableTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FCarnivorousPlantTargetSignature OnBitten;

	UPROPERTY()
	FCarnivorousPlantTargetSignature OnReachedEnd;

	UPROPERTY(EditInstanceOnly)
	AHazeActor PreviousCableActor;

	UPROPERTY()
	UMaterialInstance TurnedOffCableMaterial;

	bool bBroken = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		AlongCableTimeLike.BindUpdate(this, n"AlongCableTimeLikeUpdate");
		AlongCableTimeLike.BindFinished(this, n"AlongCableTimeLikeFinished");

		SplineComp = Spline::GetGameplaySpline(CableActor, this);
	}

	void Break()
	{
		bBroken = true;
		OnBitten.Broadcast();
		BP_Break();
		Timer::SetTimer(this, n"DelayedActivation", 1.5);

		USplitTraversalCarnivorousPlantTargetEventHandler::Trigger_OnBitten(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Break(){}

	UFUNCTION()
	private void DelayedActivation()
	{
		AlongCableVFXComp.Activate();
		AlongCableTimeLike.Play();

	}

	UFUNCTION()
	private void AlongCableTimeLikeUpdate(float CurrentValue)
	{
		AlongCableVFXComp.SetWorldLocation(SplineComp.GetWorldLocationAtSplineFraction(CurrentValue));
	}

	UFUNCTION()
	private void AlongCableTimeLikeFinished()
	{
		AlongCableVFXComp.Deactivate();
		OnReachedEnd.Broadcast();

		TArray<UActorComponent> PlatformMeshComps;
		PreviousCableActor.GetAllComponents(UStaticMeshComponent, PlatformMeshComps);

		for (auto PlatformMeshComp : PlatformMeshComps)
		{
			auto StaticMesh = Cast<UStaticMeshComponent>(PlatformMeshComp);
			if (StaticMesh != nullptr)
				StaticMesh.SetMaterial(1, TurnedOffCableMaterial);
		}
	}
};