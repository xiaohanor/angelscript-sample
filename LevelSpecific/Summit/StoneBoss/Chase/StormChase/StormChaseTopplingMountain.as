UCLASS(Abstract)
class AStormChaseTopplingMountain : AHazeActor
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UStormChaseTopplingMountainDummyComponent DummyComp;
#endif
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(EditAnywhere)
	UStaticMesh MeshOverride;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator SerpentEvent;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EditorMaterial;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve YRotationOverTimeCurve;

	UPROPERTY(EditAnywhere)
	float MovementDuration = 2;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	default DisableComp.AutoDisableRange = 120000;

	bool bIsActivated;

	float TimeWhenStartedMoving = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (MeshOverride != nullptr)
			MeshComp.SetStaticMesh(MeshOverride);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SerpentEvent.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActivated)
			return;

		float ActiveDuration = Time::GameTimeSeconds - TimeWhenStartedMoving;
		FRotator NewMeshRotation = GetMeshRotationOverTime(ActiveDuration, MovementDuration);

		FVector NewMeshLocation = GetSplineLocationOverTime(ActiveDuration, MovementDuration);
		MeshComp.SetWorldLocationAndRotation(NewMeshLocation, NewMeshRotation);
	}

	UFUNCTION()
	void OnSerpentEventTriggered()
	{
		bIsActivated = true;
		TimeWhenStartedMoving = Time::GameTimeSeconds;

		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 30000.0, 70000.0, Scale = 1.5);
	}

	FVector GetSplineLocationOverTime(float ActiveDuration, float MaxDuration)
	{
		const float TotalSplineLength = SplineComp.GetSplineLength();
		const float Alpha = ActiveDuration / MaxDuration;
		const float CurrentSplineDistance = Math::Lerp(0, TotalSplineLength, Alpha);
		auto CurrentSplinePosition = SplineComp.GetSplinePositionAtSplineDistance(CurrentSplineDistance);
		return CurrentSplinePosition.WorldLocation;
	}

	FRotator GetMeshRotationOverTime(float CurrentTime, float MaxTime)
	{
		const float Alpha = CurrentTime / MaxTime;
		const float YRotation = YRotationOverTimeCurve.GetFloatValue(Alpha);
		FVector CurrentRotationEuler = MeshComp.WorldRotation.Euler();
		CurrentRotationEuler.Y = YRotation;
		return FRotator::MakeFromEuler(CurrentRotationEuler);
	}
};

#if EDITOR
class UStormChaseTopplingMountainDummyComponent : UActorComponent
{

}

class UStormChaseTopplingMountainComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UStormChaseTopplingMountainDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UStormChaseTopplingMountainDummyComponent>(Component);
		if (Comp == nullptr)
			return;

		auto Mountain = Cast<AStormChaseTopplingMountain>(Comp.Owner);
		if (Mountain == nullptr)
			return;

		const float ActiveDuration = Time::GameTimeSeconds % Mountain.MovementDuration;

		FVector NewLocation = Mountain.GetSplineLocationOverTime(ActiveDuration, Mountain.MovementDuration);
		FRotator NewRotation = Mountain.GetMeshRotationOverTime(ActiveDuration, Mountain.MovementDuration);

		DrawMeshWithMaterial(Mountain.MeshComp.StaticMesh, Mountain.EditorMaterial, NewLocation, NewRotation.Quaternion(), Mountain.MeshComp.GetWorldScale());
	}
}
#endif