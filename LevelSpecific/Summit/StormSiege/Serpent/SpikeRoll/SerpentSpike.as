event void FOnSerpentSpikeGrow();
event void FOnSerpentSpikeSmashed();

UCLASS(Abstract)
class ASerpentSpike : AHazeActor
{
	UPROPERTY()
	FOnSerpentSpikeGrow OnSerpentSpikeGrow;

	UPROPERTY()
	FOnSerpentSpikeSmashed OnSerpentSpikeSmashed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonHomingTailSmashAutoAimComponent HomingSmashAutoAimComp;
	default HomingSmashAutoAimComp.AutoAimMaxAngle = 60.0;
	default HomingSmashAutoAimComp.TargetShape = FHazeShapeSettings::MakeBox(FVector(3700, 2700, 9250));
	default HomingSmashAutoAimComp.MaximumDistance = 20000;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(EditInstanceOnly)
	float InitialUpVectorOffset = 10000;
	FVector TargetLocation;

	UPROPERTY(EditAnywhere)
	float MoveDuration = 0.75;

#if EDITOR
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EditorMaterial;

	UPROPERTY(DefaultComponent)
	USerpentSpikeDummyComponent DummyComp;

	UFUNCTION(CallInEditor)
	void Visualize()
	{
		bIsVisualizing = true;
		AcceleratedLocation.SnapTo(ActorLocation - ActorUpVector * InitialUpVectorOffset);
	}

	bool bIsVisualizing;
#endif
	FHazeAcceleratedVector AcceleratedLocation;
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetLocation = ActorLocation;
		AddActorWorldOffset(-ActorUpVector * InitialUpVectorOffset);
		AcceleratedLocation.SnapTo(ActorLocation);
		AddActorDisable(this);

		ResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnHitBySmash");
	}

	UFUNCTION()
	private void OnHitBySmash(FTailSmashModeHitParams Params)
	{
		USerpentSpikeEffectHandler::Trigger_OnImpact(this, FSerpentSpikeImpactParams(ActorLocation));
		AddActorDisable(this);
		OnSerpentSpikeSmashed.Broadcast();
	}

	UFUNCTION()
	void ActivateSpike()
	{
		RemoveActorDisable(this);
		SetActorTickEnabled(true);
		Timer::SetTimer(this, n"OnMoveFinished", MoveDuration);
		USerpentSpikeEffectHandler::Trigger_StartGrowing(this, FSerpentSpikeImpactParams(ActorLocation));
		OnSerpentSpikeGrow.Broadcast();
	}

	UFUNCTION()
	private void OnMoveFinished()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedLocation.AccelerateTo(TargetLocation, MoveDuration, DeltaSeconds);
		SetActorLocation(AcceleratedLocation.Value);
	}
};

#if EDITOR

class USerpentSpikeDummyComponent : UActorComponent
{

}

class USerpentSpikeDummyComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USerpentSpikeDummyComponent;
	FVector CurrentVisualizationLocation;
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USerpentSpikeDummyComponent>(Component);
		if (Comp == nullptr)
			return;

		auto Spike = Cast<ASerpentSpike>(Comp.Owner);
		if (Spike == nullptr)
			return;

		if (!Spike.bIsVisualizing)
			return;

		float DeltaSeconds = Time::GetActorDeltaSeconds(Spike);
		Spike.AcceleratedLocation.AccelerateTo(Spike.ActorLocation, Spike.MoveDuration, DeltaSeconds);
		CurrentVisualizationLocation = Spike.AcceleratedLocation.Value;

		DrawMeshWithMaterial(Spike.MeshComp.StaticMesh, Spike.EditorMaterial, CurrentVisualizationLocation, Spike.MeshComp.WorldRotation.Quaternion(), Spike.MeshComp.GetWorldScale());
	}
}

#endif